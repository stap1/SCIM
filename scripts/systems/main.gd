extends Node2D

@onready var time_label: Label = $TimeLabel

# Celujemy bezposrednio w ColorRect, ktory trzyma cale UI smierci
@onready var game_over_bg = $GameOverScreen/ColorRect
@onready var restart_button = $GameOverScreen/ColorRect/RestartButton

func _ready() -> void:
	GameState.is_game_over = false
	if "is_paused" in GameState:
		GameState.is_paused = false
	if "time" in GameState:
		GameState.time = 0.0

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

	# Na starcie gry upewniamy sie, ze tlo Game Over jest niewidoczne i przezroczyste
	if game_over_bg:
		game_over_bg.hide()
		game_over_bg.modulate.a = 0.0

func _process(delta: float) -> void:
	# JEDYNE miejsce liczenia czasu w calym projekcie (HUD jest read-only).
	if not GameState.is_game_over:
		GameState.time += delta
		if time_label:
			time_label.text = "Czas: " + str(int(GameState.time)) + "s"
	else:
		# Odpalamy efekt wejscia raz, gdy gracz umrze i tlo wciaz jest schowane
		if game_over_bg and not game_over_bg.visible:
			trigger_game_over_effects()

func trigger_game_over_effects() -> void:
	if game_over_bg:
		game_over_bg.show()
		var tween = create_tween()
		tween.tween_property(game_over_bg, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		print("Kinowy efekt Game Over dziala perfekcyjnie!")

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
