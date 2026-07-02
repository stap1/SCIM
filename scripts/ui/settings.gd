extends Control

# Ekran ustawien: glosnosc Music/SFX, dlugosc sesji, accessibility (reduce shake/flash).
# Trwalosc i czyste funkcje sa w neutralnym autoloadzie SettingsStore (P1.5) - ten ekran
# tylko buduje UI i deleguje zapis/odczyt do SettingsStore. Nie zawiera juz wlasnej
# logiki persystencji/audio, by gameplay/audio nie musialy siegac do skryptu UI.

# Tylko 5 min aktywne; 10/15 wyszarzone (dluzsze sesje w przyszlym etapie).
const SESSION_LENGTHS := [5, 10, 15]
const SESSION_ENABLED := 5

@onready var music_slider: HSlider = get_node_or_null("Panel/MusicSlider")
@onready var sfx_slider: HSlider = get_node_or_null("Panel/SFXSlider")
@onready var session_option: OptionButton = get_node_or_null("Panel/SessionOption")
@onready var control_option: OptionButton = get_node_or_null("Panel/ControlOption")
@onready var reduce_shake_check: CheckButton = get_node_or_null("Panel/ReduceShakeCheck")
@onready var reduce_flash_check: CheckButton = get_node_or_null("Panel/ReduceFlashCheck")
@onready var back_button: Button = get_node_or_null("Panel/BackButton")

# Tryby sterowania widoczne w OptionButton (kolejnosc = indeksy pozycji).
var _control_modes: Array[String] = []

func _ready() -> void:
	# Build pionowy: zwez panel do szerokosci ekranu (desktop zostaje szeroki).
	if Platform.is_mobile_build():
		var panel := get_node_or_null("Panel") as Control
		if panel:
			panel.offset_left = -300.0
			panel.offset_right = 300.0
	if session_option:
		for i in SESSION_LENGTHS.size():
			session_option.add_item("%d min" % SESSION_LENGTHS[i])
			# Dluzsze sesje (10/15) wyszarzone do przyszlego etapu - tylko 5 min wybieralne.
			if SESSION_LENGTHS[i] != SESSION_ENABLED:
				session_option.set_item_disabled(i, true)

	var s := SettingsStore.load_settings(SettingsStore.SETTINGS_PATH)

	if music_slider:
		music_slider.min_value = 0.0
		music_slider.max_value = 1.0
		music_slider.step = 0.01
		music_slider.value = s["music_vol"]
		music_slider.value_changed.connect(_on_music_changed)
		# Zabezpieczenie na suwak - dzwiek gra tylko po puszczeniu, zeby nie zacinac!
		music_slider.drag_ended.connect(func(_value_changed): AudioManager.play_sfx("ui_click"))

	if sfx_slider:
		sfx_slider.min_value = 0.0
		sfx_slider.max_value = 1.0
		sfx_slider.step = 0.01
		sfx_slider.value = s["sfx_vol"]
		sfx_slider.value_changed.connect(_on_sfx_changed)
		# Zabezpieczenie na suwak - dzwiek gra tylko po puszczeniu
		sfx_slider.drag_ended.connect(func(_value_changed): AudioManager.play_sfx("ui_click"))

	if session_option:
		# Tylko 5 min aktywne - jesli zapis wskazuje wyszarzona opcje (np. stare 15), wymus 5.
		var current := int(s["session_length"])
		if current != SESSION_ENABLED:
			current = SESSION_ENABLED
			SettingsStore.session_length_min = SESSION_ENABLED
		var idx := SESSION_LENGTHS.find(current)
		session_option.selected = idx if idx != -1 else 0
		session_option.item_selected.connect(_on_session_selected)

	if control_option:
		# Tryby per platforma; biezacy z SettingsStore (juz zsanityzowany w apply_saved).
		_control_modes = ControlModes.allowed_modes(Platform.is_mobile_build())
		for m in _control_modes:
			control_option.add_item(str(ControlModes.MODE_LABELS.get(m, m)))
		var midx := _control_modes.find(SettingsStore.control_mode)
		control_option.selected = midx if midx != -1 else 0
		control_option.item_selected.connect(_on_control_selected)

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
	SettingsStore.session_length_min = SESSION_ENABLED  # tylko 5 min aktywne (10/15 wyszarzone)
	SettingsStore.reduce_shake = bool(s["reduce_shake"])
	SettingsStore.reduce_flashing = bool(s["reduce_flashing"])

	# Nawigacja klawiatura: focus na pierwszej kontrolce.
	if music_slider:
		music_slider.grab_focus()
	elif back_button:
		back_button.grab_focus()

func _on_music_changed(v: float) -> void:
	SettingsStore.apply_bus("Music", v)
	_save()

func _on_sfx_changed(v: float) -> void:
	SettingsStore.apply_bus("SFX", v)
	_save()

func _on_session_selected(idx: int) -> void:
	AudioManager.play_sfx("ui_click")
	SettingsStore.session_length_min = SESSION_LENGTHS[idx]
	_save()

func _on_control_selected(idx: int) -> void:
	AudioManager.play_sfx("ui_click")
	if idx < 0 or idx >= _control_modes.size():
		return
	var mode := _control_modes[idx]
	SettingsStore.control_mode = mode
	if mode == ControlModes.ACCEL:
		Platform.request_motion_permission() # iOS: zgoda na DeviceMotion po gescie (klik)
	_save()

func _on_reduce_shake_toggled(pressed: bool) -> void:
	AudioManager.play_sfx("ui_click")
	SettingsStore.reduce_shake = pressed
	_save()

func _on_reduce_flash_toggled(pressed: bool) -> void:
	AudioManager.play_sfx("ui_click")
	SettingsStore.reduce_flashing = pressed
	_save()

# ESC wraca do menu glownego (focus wroci na "Ustawienia" przez MainMenu._return_focus).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

func _save() -> void:
	var mv: float = music_slider.value if music_slider else 1.0
	var sv: float = sfx_slider.value if sfx_slider else 1.0
	SettingsStore.save_settings(SettingsStore.SETTINGS_PATH, mv, sv, SettingsStore.session_length_min,
		SettingsStore.reduce_shake, SettingsStore.reduce_flashing, SettingsStore.control_mode)
