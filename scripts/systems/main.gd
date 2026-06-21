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
	if spawner != null and "_spawn_budget_bonus" in spawner:
		spawner._spawn_budget_bonus = MetaProgress.enemy_budget_bonus()

enum Outcome { CONTINUE, WIN, LOSS }

var _victory_pending: bool = false

func _process(delta: float) -> void:
	# JEDYNE miejsce liczenia czasu w calym projekcie (HUD jest read-only, czyta przez sygnaly).
	if GameState.is_game_over:
		return
	GameState.add_time(delta)
	# Koniec po uplywie sesji, ALE nie gdy trwa walka z bossem (R4a) - graj az boss padnie.
	var limit_sec := SettingsStore.session_seconds(SettingsStore.session_length_min)
	var outcome := session_outcome(GameState.time, limit_sec, _boss_alive(), GameState.health <= 0.0)
	if outcome == Outcome.WIN:
		_begin_victory()
	# Porazka (smierc) konczy gra przez GameState.take_damage - tu jej nie dublujemy.

# Czysta funkcja: wynik sesji wg czasu/bossa/smierci. limit_sec <= 0 = brak limitu czasu.
# Smierc -> LOSS; czas uplynal i brak bossa -> WIN; inaczej CONTINUE (m.in. boss zyje po czasie).
static func session_outcome(time: float, limit_sec: int, boss_alive: bool, player_dead: bool) -> int:
	if player_dead:
		return Outcome.LOSS
	if limit_sec > 0 and time >= float(limit_sec) and not boss_alive:
		return Outcome.WIN
	return Outcome.CONTINUE

# Zachowane dla zgodnosci/testow: czy sam czas przekroczyl limit (bez logiki bossa).
static func should_end_session(time: float, limit_sec: int) -> bool:
	return limit_sec > 0 and time >= float(limit_sec)

# Czy na arenie jest zywy boss (motor_boat ma sygnal boss_defeated; zwykli wrogowie nie).
func _boss_alive() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_signal("boss_defeated"):
			return true
	return false

# Wygrana: laska na zebranie orbow (wstrzymany spawn, smierc nie psuje wygranej), potem ekran.
func _begin_victory() -> void:
	if _victory_pending:
		return
	_victory_pending = true
	GameState.victory_locked = true
	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null and spawner.has_method("stop_spawning"):
		spawner.stop_spawning()
	await get_tree().create_timer(GameConfig.VICTORY_COLLECT_GRACE).timeout
	GameState.trigger_game_over(true)
