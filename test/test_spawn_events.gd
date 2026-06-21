extends GutTest

# Eventy spawnu (powtarzalne, dane: typ wroga + trigger). Pierwszy: rojenie meduz
# przy "Morze nie znosi pustki" (30. zabita meduza -> zapelnienie budzetu meduzami).

const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func before_each() -> void:
	GameState.reset()

func after_each() -> void:
	_clear_enemies()

func _clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()

func _enemies_under(p: Node) -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get_parent() == p:
			n += 1
	return n

# --- Czysta funkcja triggera zabiciowego ---
func test_event_kill_triggered_once() -> void:
	assert_true(SpawnerScript.event_kill_triggered(30, false, 30), "prog 30 trafiony")
	assert_false(SpawnerScript.event_kill_triggered(30, false, 29), "29 -> nie")
	assert_false(SpawnerScript.event_kill_triggered(30, false, 31), "31 -> nie (dokladnie 30)")
	assert_false(SpawnerScript.event_kill_triggered(0, false, 0), "at<=0 -> false")

func test_event_kill_triggered_repeat() -> void:
	assert_true(SpawnerScript.event_kill_triggered(100, true, 100), "100 co 100")
	assert_true(SpawnerScript.event_kill_triggered(100, true, 300), "300 co 100")
	assert_false(SpawnerScript.event_kill_triggered(100, true, 150), "150 -> nie")

# --- Integracja: rojenie meduz zapelnia budzet ---
func test_jelly_swarm_fills_budget_on_30_kills() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var spawner = SpawnerScript.new()
	parent.add_child(spawner)
	await wait_physics_frames(1)
	GameState.reset()          # czas 0 -> budzet = BASE
	spawner.stop_spawning()    # izolacja: wylacz zwykly timer
	_clear_enemies()
	await wait_physics_frames(1)
	GameState.enemy_killed.emit(Enemy.EnemyType.JELLYFISH, 30)
	await wait_physics_frames(1)
	var n := _enemies_under(parent)
	assert_gt(n, 3, "rojenie meduz zapelnilo budzet (kilka meduz)")
	assert_lte(n, spawner.max_enemies, "nie przekracza twardego capu liczby")

func test_jelly_swarm_fires_once() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var spawner = SpawnerScript.new()
	parent.add_child(spawner)
	await wait_physics_frames(1)
	GameState.reset()
	spawner.stop_spawning()
	_clear_enemies()
	await wait_physics_frames(1)
	GameState.enemy_killed.emit(Enemy.EnemyType.JELLYFISH, 30)
	await wait_physics_frames(1)
	_clear_enemies()
	await wait_physics_frames(1)
	GameState.enemy_killed.emit(Enemy.EnemyType.JELLYFISH, 30)
	await wait_physics_frames(1)
	assert_eq(_enemies_under(parent), 0, "event jednorazowy nie odpala drugi raz")
