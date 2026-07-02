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

# Zmiana trybu sterowania na zywo - joystick ekranowy i lodz reaguja bez restartu sceny.
signal control_mode_changed(mode: String)

# --- Zywe ustawienia gracza (NIE stan sesji) - jedyne zrodlo prawdy o ustawieniach (P1.6).
# Dlugosc sesji trzymana w MINUTACH (jednostka czytelna dla gracza); przeliczenie na
# sekundy rozgrywki przez czysta funkcje session_seconds() - jeden punkt konwersji.
var session_length_min: int = 5
# Accessibility - czytane przez kod efektow (shake/flash) via should_apply_shake/should_flash.
var reduce_shake: bool = false
var reduce_flashing: bool = false
# Tryb sterowania lodzia (ControlModes.*). Default zalezy od platformy (build mobilny).
var control_mode: String = ControlModes.default_control_mode(Platform.is_mobile_build()):
	set(value):
		control_mode = value
		control_mode_changed.emit(value)

func _ready() -> void:
	# Na starcie gry: wczytaj zapisane ustawienia i zastosuj do swiata.
	apply_saved()

# Wczytaj z dysku i zastosuj: glosnosc busow audio + sesja/accessibility (do SettingsStore).
func apply_saved() -> void:
	var s := load_settings(SETTINGS_PATH)
	apply_bus("Music", s["music_vol"])
	apply_bus("SFX", s["sfx_vol"])
	session_length_min = int(s["session_length"])
	reduce_shake = bool(s["reduce_shake"])
	reduce_flashing = bool(s["reduce_flashing"])
	# Zapis z innej platformy / reczna edycja pliku -> default biezacej platformy.
	control_mode = ControlModes.sanitize_control_mode(str(s["control_mode"]), Platform.is_mobile_build())

# Ustaw glosnosc busa audio z wartosci suwaka [0,1].
func apply_bus(bus_name: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i != -1:
		AudioServer.set_bus_volume_db(i, slider_to_db(value))

# --- Czyste funkcje (testowalne, bez zaleznosci od drzewa) ---

# 0.0 -> -80 db (cisza), 1.0 -> 0 db. Liniowa interpolacja w db.
static func slider_to_db(value_0_1: float) -> float:
	return -80.0 + clampf(value_0_1, 0.0, 1.0) * 80.0

# Jedyny punkt konwersji dlugosci sesji: minuty (ustawienie) -> sekundy (czas rozgrywki).
# 0 lub mniej = brak limitu czasu (zwraca 0).
static func session_seconds(minutes: int) -> int:
	return maxi(0, minutes) * 60

# Accessibility: efekt grany tylko gdy redukcja wylaczona.
static func should_apply_shake(reduce_shake_enabled: bool) -> bool:
	return not reduce_shake_enabled

static func should_flash(reduce_flashing_enabled: bool) -> bool:
	return not reduce_flashing_enabled

static func save_settings(path: String, music_vol: float, sfx_vol: float, session_length: int,
		reduce_shake: bool = false, reduce_flashing: bool = false, control_mode: String = "") -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_vol", music_vol)
	cfg.set_value("audio", "sfx_vol", sfx_vol)
	cfg.set_value("game", "session_length", session_length)
	cfg.set_value("accessibility", "reduce_shake", reduce_shake)
	cfg.set_value("accessibility", "reduce_flashing", reduce_flashing)
	cfg.set_value("controls", "mode", control_mode)
	cfg.save(path)

static func load_settings(path: String) -> Dictionary:
	var cfg := ConfigFile.new()
	var result := {
		"music_vol": 1.0, "sfx_vol": 1.0, "session_length": 5,
		"reduce_shake": false, "reduce_flashing": false, "control_mode": "",
	}
	if cfg.load(path) == OK:
		result["music_vol"] = cfg.get_value("audio", "music_vol", 1.0)
		result["sfx_vol"] = cfg.get_value("audio", "sfx_vol", 1.0)
		result["session_length"] = cfg.get_value("game", "session_length", 5)
		result["reduce_shake"] = cfg.get_value("accessibility", "reduce_shake", false)
		result["reduce_flashing"] = cfg.get_value("accessibility", "reduce_flashing", false)
		result["control_mode"] = cfg.get_value("controls", "mode", "")
	return result
