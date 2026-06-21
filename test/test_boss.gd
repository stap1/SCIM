extends GutTest

# KROK 18 (Prompt 18) - GATE 2: mini-boss MotorBoat.

const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")
const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func before_each() -> void:
	GameState.reset()

func test_motorboat_stats_and_group() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	assert_almost_eq(boss.max_health, 300.0, 0.001, "MotorBoat max_health 300")
	assert_true(boss.is_in_group("enemies"), "MotorBoat w grupie enemies")

func test_should_spawn_boss() -> void:
	assert_true(SpawnerScript.should_spawn_boss(210.0, false), "time>=210 i nie spawniony -> true")
	assert_false(SpawnerScript.should_spawn_boss(210.0, true), "juz spawniony -> false")
	assert_false(SpawnerScript.should_spawn_boss(209.0, false), "tuz przed progiem -> false")
	assert_false(SpawnerScript.should_spawn_boss(100.0, false), "za wczesnie -> false")

func test_double_die_does_not_crash() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	boss.die()
	boss.die() # guard is_dying
	assert_true(boss.is_dying)
	pass_test("podwojne die() bossa nie crashuje (guard)")
	await wait_physics_frames(1)

func test_die_adds_score_and_emits_boss_defeated() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	var before: int = GameState.score
	var ks: int = boss.kill_score
	watch_signals(boss)
	boss.die()
	assert_eq(GameState.score, before + ks, "die() bossa dodaje kill_score (500)")
	assert_signal_emitted(boss, "boss_defeated", "die() emituje boss_defeated")
	await wait_physics_frames(1)

func test_spawner_spawns_boss_exactly_once() -> void:
	var spawner = SpawnerScript.new()
	spawner.max_enemies = 0 # tylko boss (regularne pomijane przez limit)
	add_child_autofree(spawner)
	await wait_physics_frames(1)
	GameState.time = 211.0
	spawner._on_timeout()
	assert_eq(_count_bosses(), 1, "boss spawniony raz po 210s")
	spawner._on_timeout()
	assert_eq(_count_bosses(), 1, "guard: brak drugiego bossa")
	# Sprzatanie wrogow dodanych do drzewa testowego.
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.queue_free()
	await wait_physics_frames(1)

func _count_bosses() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_signal("boss_defeated"):
			n += 1
	return n
