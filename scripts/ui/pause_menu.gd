extends CanvasLayer

## Menu pauzy. Pauza realizowana natywnie: get_tree().paused = true wstrzymuje cale
## drzewo, a ten wezel ma process_mode = ALWAYS, wiec menu i jego przyciski dzialaja
## mimo wstrzymania reszty gry.
##
## Wzorzec "jeden wlasciciel pauzy": menu otwiera pauze TYLKO w aktywnej rozgrywce.
## Gdy drzewo jest juz wstrzymane przez inny ekran (wybor ulepszenia) albo trwa game
## over, klawisz pauzy jest ignorowany - to zapobiega konfliktowi dwoch niezaleznych
## wlascicieli flagi get_tree().paused.

@onready var _dimmer: Control = $Dimmer
@onready var _menu_root: VBoxContainer = $Dimmer/Center/Menu
@onready var _resume_button: Button = $Dimmer/Center/Menu/ResumeButton
@onready var _settings_button: Button = $Dimmer/Center/Menu/SettingsButton
@onready var _restart_button: Button = $Dimmer/Center/Menu/RestartButton
@onready var _menu_button: Button = $Dimmer/Center/Menu/MenuButton
# Panel ustawien w pauzie (w miejscu - bez opuszczania rozgrywki).
@onready var _settings_panel: VBoxContainer = $Dimmer/Center/SettingsPanel
@onready var _music_slider: HSlider = $Dimmer/Center/SettingsPanel/MusicSlider
@onready var _sfx_slider: HSlider = $Dimmer/Center/SettingsPanel/SFXSlider
@onready var _reduce_shake_check: CheckButton = $Dimmer/Center/SettingsPanel/ReduceShakeCheck
@onready var _reduce_flash_check: CheckButton = $Dimmer/Center/SettingsPanel/ReduceFlashCheck
@onready var _control_option: OptionButton = get_node_or_null("Dimmer/Center/SettingsPanel/ControlOption")
@onready var _settings_back: Button = $Dimmer/Center/SettingsPanel/BackButton

# Tryby sterowania widoczne w OptionButton pauzy (kolejnosc = indeksy pozycji).
var _control_modes: Array[String] = []

## Czy to menu jest aktualnym wlascicielem pauzy. Chroni przed "przejeciem" pauzy
## zalozonej przez inny ekran (np. wznowienie gry w trakcie wyboru ulepszenia).
var _is_open: bool = false
## Tryb nakladki: pauza otwarta NAD innym ekranem (np. level-up), ktory juz trzyma pauze.
## Wznowienie wtedy NIE zdejmuje pauzy - oddaje sterowanie temu ekranowi (sygnal overlay_closed).
var _overlay: bool = false
signal overlay_closed

func _ready() -> void:
	# Pewnik na wypadek braku ustawienia w .tscn - menu musi dzialac przy pauzie.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")  # level-up znajduje pauze przez grupe (luzne powiazanie)
	_dimmer.hide()
	_resume_button.pressed.connect(resume)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_settings_button.pressed.connect(_open_settings)
	_settings_back.pressed.connect(_close_settings)
	_init_settings_controls()
	_settings_panel.hide()

## Obsluga klawisza pauzy. _unhandled_input dziala dla wezlow ALWAYS takze przy
## get_tree().paused, a uruchamia sie dopiero gdy zdarzenia nie skonsumowal zaden Control.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()

## Przelacza pauze z poszanowaniem wlasnosci (patrz docstring klasy). Publiczne -
## wolane przez klawisz pauzy oraz w testach.
func toggle() -> void:
	if GameState.is_game_over:
		return                      # po smierci pauza nie ma sensu (jest ekran wynikow)
	if _is_open:
		resume()
	elif not get_tree().paused:
		_open()
	# else: drzewo wstrzymane przez inny ekran - swiadomie ignorujemy.

## Otwiera menu i wstrzymuje rozgrywke.
func _open() -> void:
	AudioManager.play_sfx("ui_click") # Dzwiek przy wejsciu w pauze ESC/klawiszem
	_is_open = true
	GameState.is_paused = true      # spojnosc dla systemow czytajacych te flage
	get_tree().paused = true
	# Zawsze otwieraj na glownych przyciskach pauzy (panel ustawien schowany).
	_settings_panel.hide()
	_menu_root.show()
	_dimmer.show()
	_resume_button.grab_focus()     # ergonomia: od razu nawigacja klawiatura/pad

## Otwiera pauze jako NAKLADKE nad ekranem, ktory juz trzyma pauze (np. level-up).
## Nie rusza get_tree().paused (juz wstrzymane). Wznowienie odda sterowanie przez overlay_closed.
func open_overlay() -> void:
	if _is_open:
		return
	AudioManager.play_sfx("ui_click")
	_is_open = true
	_overlay = true
	_settings_panel.hide()
	_menu_root.show()
	_dimmer.show()
	_resume_button.grab_focus()

func is_overlay_open() -> bool:
	return _is_open and _overlay

## Wznawia rozgrywke. Publiczne - podpiete pod przycisk "Wznow" oraz klawisz pauzy.
func resume() -> void:
	AudioManager.play_sfx("ui_click")
	_is_open = false
	_dimmer.hide()
	_settings_panel.hide()
	_menu_root.show()
	if _overlay:
		# Nakladka nad level-up: nie zdejmuj pauzy - oddaj sterowanie ekranowi pod spodem.
		_overlay = false
		overlay_closed.emit()
		return
	GameState.is_paused = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_leave_session()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_leave_session()
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

## Wspolne sprzatanie przed opuszczeniem rozgrywki: zdejmij pauze i zresetuj sesje,
## by nowa gra (restart/menu) startowala z czystym GameState.
func _leave_session() -> void:
	_is_open = false
	GameState.is_paused = false
	get_tree().paused = false
	GameState.reset()

# --- Ustawienia w pauzie (w miejscu, bez opuszczania sesji) ---

func _open_settings() -> void:
	AudioManager.play_sfx("ui_click")
	_refresh_settings_values()
	_menu_root.hide()
	_settings_panel.show()
	_settings_back.grab_focus()

func _close_settings() -> void:
	AudioManager.play_sfx("ui_click")
	_settings_panel.hide()
	_menu_root.show()
	_settings_button.grab_focus()

func _init_settings_controls() -> void:
	if _control_option:
		_control_modes = ControlModes.allowed_modes(Platform.is_mobile_build())
		for m in _control_modes:
			_control_option.add_item(str(ControlModes.MODE_LABELS.get(m, m)))
		_control_option.item_selected.connect(_on_control_selected)
	_refresh_settings_values()
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_reduce_shake_check.toggled.connect(_on_reduce_shake_toggled)
	_reduce_flash_check.toggled.connect(_on_reduce_flash_toggled)

# Wczytuje biezace wartosci do kontrolek (bez emisji sygnalow - by nie nadpisac zapisu).
func _refresh_settings_values() -> void:
	var s := SettingsStore.load_settings(SettingsStore.SETTINGS_PATH)
	_music_slider.set_value_no_signal(float(s["music_vol"]))
	_sfx_slider.set_value_no_signal(float(s["sfx_vol"]))
	_reduce_shake_check.set_pressed_no_signal(bool(s["reduce_shake"]))
	_reduce_flash_check.set_pressed_no_signal(bool(s["reduce_flashing"]))
	if _control_option:
		# Tryb czytany z zywego SettingsStore (juz zsanityzowany), nie z surowego pliku.
		var midx := _control_modes.find(SettingsStore.control_mode)
		if midx != -1:
			_control_option.selected = midx

func _on_music_changed(v: float) -> void:
	SettingsStore.apply_bus("Music", v)
	_save_settings()

func _on_sfx_changed(v: float) -> void:
	SettingsStore.apply_bus("SFX", v)
	_save_settings()

func _on_reduce_shake_toggled(pressed: bool) -> void:
	AudioManager.play_sfx("ui_click")
	SettingsStore.reduce_shake = pressed
	_save_settings()

func _on_reduce_flash_toggled(pressed: bool) -> void:
	AudioManager.play_sfx("ui_click")
	SettingsStore.reduce_flashing = pressed
	_save_settings()

func _on_control_selected(idx: int) -> void:
	AudioManager.play_sfx("ui_click")
	if idx < 0 or idx >= _control_modes.size():
		return
	SettingsStore.control_mode = _control_modes[idx]
	_save_settings()

# Zapis przez SettingsStore (jedyny wlasciciel trwalosci). Dlugosc sesji bez zmian w pauzie.
func _save_settings() -> void:
	SettingsStore.save_settings(SettingsStore.SETTINGS_PATH, _music_slider.value, _sfx_slider.value,
		SettingsStore.session_length_min, _reduce_shake_check.button_pressed,
		_reduce_flash_check.button_pressed, SettingsStore.control_mode)
