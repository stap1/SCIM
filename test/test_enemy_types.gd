extends GutTest

# KROK 16 (Prompt 16): trzy typy wrogow z jednej bazy (enemy.gd), rozne eksporty.

const BarracudaScene := preload("res://scenes/enemies/barracuda.tscn")
const SharkScene := preload("res://scenes/enemies/shark.tscn")

func before_each() -> void:
	GameState.reset()

func test_barracuda_stats() -> void:
	var b = BarracudaScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	assert_almost_eq(b.max_health, 8.0, 0.001, "Barracuda max_health 8")
	assert_almost_eq(b.speed, 160.0, 0.001, "Barracuda speed 160")
	assert_eq(b.kill_score, 2, "Barracuda kill_score 2")

func test_shark_stats() -> void:
	var s = SharkScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	assert_almost_eq(s.max_health, 40.0, 0.001, "Shark max_health 40")
	assert_almost_eq(s.speed, 50.0, 0.001, "Shark speed 50")
	assert_eq(s.kill_score, 5, "Shark kill_score 5")

func test_both_in_enemies_group() -> void:
	var b = BarracudaScene.instantiate()
	var s = SharkScene.instantiate()
	add_child_autofree(b)
	add_child_autofree(s)
	await wait_physics_frames(1)
	assert_true(b.is_in_group("enemies"), "Barracuda w grupie enemies")
	assert_true(s.is_in_group("enemies"), "Shark w grupie enemies")

func test_kill_score_per_type() -> void:
	var b = BarracudaScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	var before: int = GameState.score
	b.take_damage(b.max_health) # smiertelne -> die() -> add_score(kill_score)
	assert_eq(GameState.score, before + 2, "Barracuda daje kill_score 2 do GameState")
	await wait_physics_frames(1)

	GameState.reset()
	var s = SharkScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	var before2: int = GameState.score
	s.take_damage(s.max_health)
	assert_eq(GameState.score, before2 + 5, "Shark daje kill_score 5 do GameState")
	await wait_physics_frames(1)
