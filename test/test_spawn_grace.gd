extends GutTest

# Karencja startowa spawnera (fix obrazen na poczatku rozgrywki).
# Przez pierwsze GameConfig.SPAWN_GRACE_SECONDS spawner nie wypuszcza zwyklych wrogow.

const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func before_each() -> void:
	GameState.reset()

func test_is_in_grace_pure() -> void:
	assert_true(SpawnerScript.is_in_grace(0.0, 5.0), "t=0 -> w karencji")
	assert_true(SpawnerScript.is_in_grace(4.9, 5.0), "t<grace -> w karencji")
	assert_false(SpawnerScript.is_in_grace(5.0, 5.0), "t=grace -> koniec karencji")
	assert_false(SpawnerScript.is_in_grace(10.0, 5.0), "t>grace -> brak karencji")

func test_grace_default_is_five_seconds() -> void:
	assert_almost_eq(GameConfig.SPAWN_GRACE_SECONDS, 5.0, 0.001, "domyslna karencja 5 s")

func test_no_regular_spawn_during_grace() -> void:
	var spawner = SpawnerScript.new()
	add_child_autofree(spawner)
	await wait_physics_frames(1)
	GameState.time = 2.0 # w karencji
	var before: int = get_tree().get_nodes_in_group("enemies").size()
	spawner._on_timeout()
	assert_eq(get_tree().get_nodes_in_group("enemies").size(), before,
		"w karencji spawner nie dodaje zwyklych wrogow")
	await wait_physics_frames(1)
