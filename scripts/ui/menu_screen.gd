class_name MenuScreen
extends Control

# Wspolna baza podekranow menu (Wyniki, Credits, Historia zmian): spina Panel/BackButton
# i ESC (ui_cancel) z powrotem do menu glownego + sfx klikniecia. Ekran-dziecko nadpisuje
# _ready()/_unhandled_input() i wola super(), zanim doda wlasna logike.

func _ready() -> void:
	var back := get_node_or_null("Panel/BackButton") as Button
	if back:
		back.pressed.connect(_on_back)
		back.grab_focus()  # nawigacja klawiatura

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC -> powrot do menu
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
