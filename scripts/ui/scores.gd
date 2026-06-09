extends Control

# Ekran najlepszych wynikow (top 5) - czytany z HighScores. Powrot do menu.

const HighScores := preload("res://scripts/systems/highscores.gd")

@onready var list_label: Label = get_node_or_null("Panel/ScoresList")
@onready var back_button: Button = get_node_or_null("Panel/BackButton")

func _ready() -> void:
	_show_scores()
	if back_button:
		back_button.pressed.connect(_on_back)

func _show_scores() -> void:
	if list_label == null:
		return
	list_label.text = format_scores(HighScores.get_top(5))

func _on_back() -> void:
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

# Czysta funkcja: tekst listy wynikow (numerowany, malejaco) lub komunikat gdy pusto.
static func format_scores(top: Array[int]) -> String:
	if top.is_empty():
		return "Brak wynikow"
	var text := ""
	for i in top.size():
		text += "%d.   %d\n" % [i + 1, top[i]]
	return text
