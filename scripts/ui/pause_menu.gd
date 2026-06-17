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
@onready var _resume_button: Button = $Dimmer/Center/Menu/ResumeButton
@onready var _restart_button: Button = $Dimmer/Center/Menu/RestartButton
@onready var _menu_button: Button = $Dimmer/Center/Menu/MenuButton

## Czy to menu jest aktualnym wlascicielem pauzy. Chroni przed "przejeciem" pauzy
## zalozonej przez inny ekran (np. wznowienie gry w trakcie wyboru ulepszenia).
var _is_open: bool = false

func _ready() -> void:
	# Pewnik na wypadek braku ustawienia w .tscn - menu musi dzialac przy pauzie.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dimmer.hide()
	_resume_button.pressed.connect(resume)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)

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
	_dimmer.show()
	_resume_button.grab_focus()     # ergonomia: od razu nawigacja klawiatura/pad

## Wznawia rozgrywke. Publiczne - podpiete pod przycisk "Wznow" oraz klawisz pauzy.
func resume() -> void:
	AudioManager.play_sfx("ui_click")
	_is_open = false
	GameState.is_paused = false
	get_tree().paused = false
	_dimmer.hide()

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
