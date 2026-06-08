extends GutTest

# KROK 11 (Prompt 11) - VERTICAL SLICE / GATE 0: score per kill, sygnal died, smoke calej sceny.

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const MainScene := preload("res://scenes/Main.tscn")

func before_each() -> void:
	GameState.reset()

func test_die_adds_kill_score() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	await wait_physics_frames(1)
	var before: int = GameState.score
	var ks: int = enemy.kill_score
	enemy.die()
	assert_eq(GameState.score, before + ks, "die() zwieksza score o kill_score")

func test_die_emits_died_with_position() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	enemy.global_position = Vector2(123, 45)
	await wait_physics_frames(1)
	watch_signals(enemy)
	enemy.die()
	assert_signal_emitted(enemy, "died", "die() emituje sygnal died")
	var params = get_signal_parameters(enemy, "died")
	assert_eq(params[0], Vector2(123, 45), "died niesie pozycje wroga")

func test_main_scene_smoke() -> void:
	var main = MainScene.instantiate()
	add_child_autofree(main)
	await wait_physics_frames(15)
	assert_true(is_instance_valid(main), "Main.tscn dziala kilka klatek bez crasha")
