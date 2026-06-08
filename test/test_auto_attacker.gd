extends GutTest

# KROK 10 (Prompt 10): auto-celowanie. Czysta find_nearest + integracja cyklu ataku.

const AutoAttackerScript := preload("res://scripts/systems/auto_attacker.gd")
const HarpoonPoolScript := preload("res://scripts/weapons/harpoon_pool.gd")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")

func before_each() -> void:
	GameState.reset()

func test_find_nearest_in_range() -> void:
	var positions: Array[Vector2] = [Vector2(100, 0), Vector2(10, 0), Vector2(500, 0)]
	assert_eq(AutoAttackerScript.find_nearest(Vector2.ZERO, positions, 350.0), 1,
		"najblizszy w zasiegu to indeks 1 (500 poza zasiegiem)")

func test_find_nearest_all_out_of_range() -> void:
	var positions: Array[Vector2] = [Vector2(1000, 0), Vector2(0, 800)]
	assert_eq(AutoAttackerScript.find_nearest(Vector2.ZERO, positions, 350.0), -1,
		"wszystko poza zasiegiem -> -1")

func test_attack_cycle_fires_at_enemy() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO

	var enemy = EnemyScene.instantiate()
	add_child_autofree(enemy)
	enemy.global_position = Vector2(100, 0)

	var pool = HarpoonPoolScript.new()
	pool.pool_size = 5
	add_child_autofree(pool)

	var auto = AutoAttackerScript.new()
	auto.attack_range = 350.0
	add_child_autofree(auto)

	await wait_physics_frames(1)
	auto._on_timeout() # jeden cykl ataku

	var fired = null
	for h in pool.get_children():
		if h.has_method("fire") and h.active:
			fired = h
			break
	assert_not_null(fired, "po cyklu ataku jeden harpun stal sie aktywny")
	if fired:
		assert_gt(fired.direction.x, 0.5, "harpun leci ku wrogowi (kierunek +x)")
	await wait_physics_frames(1)
