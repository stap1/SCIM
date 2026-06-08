extends Node

# Neutralny magazyn ustawien gracza: audio (glosnosc), sesja (dlugosc), accessibility
# (reduce shake/flash). JEDYNY wlasciciel trwalosci (ConfigFile) oraz czystych funkcji
# ustawien (slider_to_db / should_apply_shake / should_flash).
#
# Gameplay (boat), audio (AudioManager) i ekran ustawien (settings.gd) czytaja STAD,
# nigdy nawzajem ze skryptu ekranu UI - to usuwa coupling gameplay/audio -> UI (P1.5).
#
# Autoload PO GameState (zapisuje sesje/accessibility do GameState) i PRZED AudioManager
# (ustawia glosnosc busow zanim audio rusza).

const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	# Na starcie gry: wczytaj zapisane ustawienia i zastosuj do swiata.
	apply_saved()

# Wczytaj z dysku i zastosuj: glosnosc busow audio + sesja/accessibility do GameState.
func apply_saved() -> void:
	var s := load_settings(SETTINGS_PATH)
	apply_bus("Music", s["music_vol"])
	apply_bus("SFX", s["sfx_vol"])
	GameState.session_length = int(s["session_length"])
	GameState.reduce_shake = bool(s["reduce_shake"])
	GameState.reduce_flashing = bool(s["reduce_flashing"])

# Ustaw glosnosc busa audio z wartosci suwaka [0,1].
func apply_bus(bus_name: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i != -1:
		AudioServer.set_bus_volume_db(i, slider_to_db(value))

# --- Czyste funkcje (testowalne, bez zaleznosci od drzewa) ---

# 0.0 -> -80 db (cisza), 1.0 -> 0 db. Liniowa interpolacja w db.
static func slider_to_db(value_0_1: float) -> float:
	return -80.0 + clampf(value_0_1, 0.0, 1.0) * 80.0

# Accessibility: efekt grany tylko gdy redukcja wylaczona.
static func should_apply_shake(reduce_shake_enabled: bool) -> bool:
	return not reduce_shake_enabled

static func should_flash(reduce_flashing_enabled: bool) -> bool:
	return not reduce_flashing_enabled

static func save_settings(path: String, music_vol: float, sfx_vol: float, session_length: int,
		reduce_shake: bool = false, reduce_flashing: bool = false) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_vol", music_vol)
	cfg.set_value("audio", "sfx_vol", sfx_vol)
	cfg.set_value("game", "session_length", session_length)
	cfg.set_value("accessibility", "reduce_shake", reduce_shake)
	cfg.set_value("accessibility", "reduce_flashing", reduce_flashing)
	cfg.save(path)

static func load_settings(path: String) -> Dictionary:
	var cfg := ConfigFile.new()
	var result := {
		"music_vol": 1.0, "sfx_vol": 1.0, "session_length": 15,
		"reduce_shake": false, "reduce_flashing": false,
	}
	if cfg.load(path) == OK:
		result["music_vol"] = cfg.get_value("audio", "music_vol", 1.0)
		result["sfx_vol"] = cfg.get_value("audio", "sfx_vol", 1.0)
		result["session_length"] = cfg.get_value("game", "session_length", 15)
		result["reduce_shake"] = cfg.get_value("accessibility", "reduce_shake", false)
		result["reduce_flashing"] = cfg.get_value("accessibility", "reduce_flashing", false)
	return result
