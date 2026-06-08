extends Control

# Ekran ustawien: glosnosc Music/SFX, dlugosc sesji, accessibility (reduce shake/flash).
# Trwalosc i czyste funkcje sa w neutralnym autoloadzie SettingsStore (P1.5) - ten ekran
# tylko buduje UI i deleguje zapis/odczyt do SettingsStore. Nie zawiera juz wlasnej
# logiki persystencji/audio, by gameplay/audio nie musialy siegac do skryptu UI.

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

	var s := SettingsStore.load_settings(SettingsStore.SETTINGS_PATH)

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

	SettingsStore.apply_bus("Music", s["music_vol"])
	SettingsStore.apply_bus("SFX", s["sfx_vol"])
	SettingsStore.session_length_min = int(s["session_length"])
	SettingsStore.reduce_shake = bool(s["reduce_shake"])
	SettingsStore.reduce_flashing = bool(s["reduce_flashing"])

func _on_music_changed(v: float) -> void:
	SettingsStore.apply_bus("Music", v)
	_save()

func _on_sfx_changed(v: float) -> void:
	SettingsStore.apply_bus("SFX", v)
	_save()

func _on_session_selected(idx: int) -> void:
	SettingsStore.session_length_min = SESSION_LENGTHS[idx]
	_save()

func _on_reduce_shake_toggled(pressed: bool) -> void:
	SettingsStore.reduce_shake = pressed
	_save()

func _on_reduce_flash_toggled(pressed: bool) -> void:
	SettingsStore.reduce_flashing = pressed
	_save()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _save() -> void:
	var mv: float = music_slider.value if music_slider else 1.0
	var sv: float = sfx_slider.value if sfx_slider else 1.0
	SettingsStore.save_settings(SettingsStore.SETTINGS_PATH, mv, sv, SettingsStore.session_length_min,
		SettingsStore.reduce_shake, SettingsStore.reduce_flashing)
