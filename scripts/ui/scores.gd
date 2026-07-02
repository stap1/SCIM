extends MenuScreen

# Ekran najlepszych wynikow (top 5) - czytany z HighScores. Powrot/ESC: baza MenuScreen.

const HighScores := preload("res://scripts/systems/highscores.gd")

@onready var list_label: Label = get_node_or_null("Panel/ScoresList")

func _ready() -> void:
	super()
	_show_scores()

func _show_scores() -> void:
	if list_label == null:
		return
	list_label.text = format_scores(HighScores.get_top(5))

# Czysta funkcja: tekst listy wynikow (numerowany, malejaco) lub komunikat gdy pusto.
# Wpisy to slowniki {"name", "score"}.
static func format_scores(top: Array[Dictionary]) -> String:
	if top.is_empty():
		return "Brak wyników"
	var text := ""
	for i in top.size():
		var e: Dictionary = top[i]
		text += "%d.  %s  -  %d\n" % [i + 1, str(e.get("name", HighScores.DEFAULT_NAME)), int(e.get("score", 0))]
	return text
