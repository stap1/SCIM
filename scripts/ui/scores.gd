extends Control

# Ekran najlepszych wynikow (top 5) - czytany z HighScores. Powrot do menu.

const HighScores := preload("res://scripts/systems/highscores.gd")

@onready var list_label: Label = get_node_or_null("Panel/ScoresList")
@onready var back_button: Button = get_node_or_null("Panel/BackButton")

func _ready() -> void:
	_show_scores()
	if back_button:
		back_button.pressed.connect(_on_back)
		back_button.grab_focus()  # nawigacja klawiatura

func _show_scores() -> void:
	if list_label == null:
		return
	list_label.text = format_scores(HighScores.get_top(5))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC -> powrot do menu
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

# Czysta funkcja: tekst listy wynikow (numerowany, malejaco) lub komunikat gdy pusto.
# Wpisy to slowniki {"name", "score"}.
static func format_scores(top: Array) -> String:
	if top.is_empty():
		return "Brak wyników"
	var text := ""
	for i in top.size():
		var e = top[i]
		text += "%d.  %s  -  %d\n" % [i + 1, str(e.get("name", "Anonim")), int(e.get("score", 0))]
	return text
