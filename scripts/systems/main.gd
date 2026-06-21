extends Node2D

func _ready() -> void:
	GameState.is_game_over = false
	if "is_paused" in GameState:
		GameState.is_paused = false
	if "time" in GameState:
		GameState.time = 0.0
	_apply_meta_upgrades()

# Nakłada trwałe ulepszenia (MetaProgress) na start runu: zasięg zbierania, prędkość łodzi,
# złagodzenie spawnu. Dzieci (boat, spawner) są już gotowe (_ready dzieci idzie przed root).
# Centralizacja tutaj trzyma boat/spawner odsprzężone od MetaProgress.
func _apply_meta_upgrades() -> void:
	GameState.magnet_range_mult = MetaProgress.bonus_magnet_mult()
	var boat := get_tree().get_first_node_in_group("player")
	if boat != null and "max_speed" in boat:
		boat.max_speed += MetaProgress.bonus_boat_speed()
	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null and "_spawn_ease" in spawner:
		spawner._spawn_ease = MetaProgress.spawn_ease()

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
