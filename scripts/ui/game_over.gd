extends CanvasLayer

# Ekran konca gry. Reaguje na sygnal GameState.game_over, pauzuje gre i pozwala zrestartowac.
# CanvasLayer ma process_mode = ALWAYS, by przycisk dzialal mimo get_tree().paused.

@onready var panel: Control = $Panel
@onready var final_score_label: Label = $Panel/FinalScoreLabel
@onready var restart_button: Button = $Panel/RestartButton

func _ready() -> void:
	if panel:
		panel.hide()
	GameState.game_over.connect(_on_game_over)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

func _on_game_over() -> void:
	if final_score_label:
		final_score_label.text = "Wynik: " + str(GameState.score)
	if panel:
		panel.show()
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()
