extends Node2D

func _ready() -> void:
	GameState.is_game_over = false
	if "is_paused" in GameState:
		GameState.is_paused = false
	if "time" in GameState:
		GameState.time = 0.0

func _process(delta: float) -> void:
	# JEDYNE miejsce liczenia czasu w calym projekcie (HUD jest read-only, czyta przez sygnaly).
	if not GameState.is_game_over:
		GameState.add_time(delta)
