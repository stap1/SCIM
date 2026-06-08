extends Control

# Ekran ustawien: glosnosc Music/SFX, dlugosc sesji, accessibility (reduce shake/flash).
# Zapis/odczyt przez ConfigFile (user://settings.cfg). Czyste funkcje na dole.

const SETTINGS_PATH := "user://settings.cfg"
const SESSION_LENGTHS := [10, 15, 20]

@onready var music_slider: HSlider = get_node_or_null("Panel/MusicSlider")
@onready var sfx_slider: HSlider = get_node_or_null("Panel/SFXSlider")
@onready var session_option: OptionButton = get_node_or_null("Panel/SessionOption")
@onready var reduce_shake_check: CheckButton = get_node_or_null("Panel/ReduceShakeCheck")
@onready var reduce_flash_check: CheckButton = get_node_or_null("Panel/ReduceFlashCheck")
@onready var back_button: Button = get_node_or_null("Panel/BackButton")

func _ready() -> void:
	if session_option:
		for length in SESSION_LENGTHS:
			session_option.add_item("%d min" % length)

	var s := load_settings(SETTINGS_PATH)

	if music_slider:
		music_slider.min_value = 0.0
		music_slider.max_value = 1.0
		music_slider.step = 0.01
		music_slider.value = s["music_vol"]
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.min_value = 0.0
		sfx_slider.max_value = 1.0
		sfx_slider.step = 0.01
		sfx_slider.value = s["sfx_vol"]
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if session_option:
		var idx := SESSION_LENGTHS.find(int(s["session_length"]))
		session_option.selected = idx if idx != -1 else 1
		session_option.item_selected.connect(_on_session_selected)
	if reduce_shake_check:
		reduce_shake_check.button_pressed = bool(s["reduce_shake"])
		reduce_shake_check.toggled.connect(_on_reduce_shake_toggled)
	if reduce_flash_check:
		reduce_flash_check.button_pressed = bool(s["reduce_flashing"])
		reduce_flash_check.toggled.connect(_on_reduce_flash_toggled)
	if back_button:
		back_button.pressed.connect(_on_back)

	_apply_bus("Music", s["music_vol"])
	_apply_bus("SFX", s["sfx_vol"])
	GameState.session_length = int(s["session_length"])
	GameState.reduce_shake = bool(s["reduce_shake"])
	GameState.reduce_flashing = bool(s["reduce_flashing"])

func _on_music_changed(v: float) -> void:
	_apply_bus("Music", v)
	_save()

func _on_sfx_changed(v: float) -> void:
	_apply_bus("SFX", v)
	_save()

func _on_session_selected(idx: int) -> void:
	GameState.session_length = SESSION_LENGTHS[idx]
	_save()

func _on_reduce_shake_toggled(pressed: bool) -> void:
	GameState.reduce_shake = pressed
	_save()

func _on_reduce_flash_toggled(pressed: bool) -> void:
	GameState.reduce_flashing = pressed
	_save()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _apply_bus(bus_name: String, value: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i != -1:
		AudioServer.set_bus_volume_db(i, slider_to_db(value))

func _save() -> void:
	var mv: float = music_slider.value if music_slider else 1.0
	var sv: float = sfx_slider.value if sfx_slider else 1.0
	save_settings(SETTINGS_PATH, mv, sv, GameState.session_length,
		GameState.reduce_shake, GameState.reduce_flashing)

# --- Czyste funkcje (testowalne) ---

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
