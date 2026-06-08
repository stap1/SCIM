extends GutTest

# KROK 5 (Prompt 5): wrog Jellyfish (CharacterBody2D) + spawner.

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func test_enemy_starts_with_full_health() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	await wait_physics_frames(1)
	assert_eq(enemy.health, enemy.max_health, "health startuje rowne max_health")
	assert_eq(enemy.max_health, 10.0, "max_health == 10.0")
	enemy.queue_free()

func test_take_damage_triggers_die() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	await wait_physics_frames(1)
	enemy.take_damage(10.0)
	assert_true(enemy.is_dying, "take_damage(10) doprowadza health<=0 i wywoluje die()")
	await wait_seconds(1.1)

func test_double_die_does_not_crash() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	await wait_physics_frames(1)
	enemy.die()
	enemy.die()
	assert_true(enemy.is_dying)
	pass_test("Podwojne die() nie wywolalo bledu (guard)")
	await wait_seconds(1.1)

func test_spawn_position_for_edge_is_outside_viewport() -> void:
	var vp := Vector2(1000, 800)
	# 0=gora, 1=prawo, 2=dol, 3=lewo
	var top: Vector2 = SpawnerScript.spawn_position_for_edge(0, vp)
	assert_lt(top.y, 0.0, "gora: y < 0 (poza ekranem)")
	var right: Vector2 = SpawnerScript.spawn_position_for_edge(1, vp)
	assert_gt(right.x, vp.x, "prawo: x > szerokosc")
	var bottom: Vector2 = SpawnerScript.spawn_position_for_edge(2, vp)
	assert_gt(bottom.y, vp.y, "dol: y > wysokosc")
	var left: Vector2 = SpawnerScript.spawn_position_for_edge(3, vp)
	assert_lt(left.x, 0.0, "lewo: x < 0")
