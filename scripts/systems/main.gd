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
		# Koniec gry po uplywie ustawionej dlugosci sesji (limit w sekundach z SettingsStore).
		var limit_sec := SettingsStore.session_seconds(SettingsStore.session_length_min)
		if should_end_session(GameState.time, limit_sec):
			GameState.trigger_game_over()

# Czysta funkcja: czy sesja powinna sie zakonczyc wg czasu. limit_sec <= 0 = brak limitu.
static func should_end_session(time: float, limit_sec: int) -> bool:
	return limit_sec > 0 and time >= float(limit_sec)
