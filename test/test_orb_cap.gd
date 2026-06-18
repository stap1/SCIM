extends GutTest

# FAZA 6: model 1 orb=1XP - rozrzut wielu orbow + cap chroniacy FPS (nadmiar oddaje XP).

const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

var _root: Node2D

func before_each() -> void:
	GameState.reset()
	_root = Node2D.new()
	add_child_autofree(_root)

func _make_spawner() -> Node:
	var sp := Node.new()
	sp.set_script(SpawnerScript)
	_root.add_child(sp)  # spawner.get_parent() == _root -> tam ida orby
	return sp

func test_spawn_creates_value_orbs() -> void:
	var sp := _make_spawner()
	var before := get_tree().get_nodes_in_group("xp_orbs").size()
	sp._spawn_orbs(Vector2.ZERO, 5, 1)
	assert_eq(get_tree().get_nodes_in_group("xp_orbs").size() - before, 5, "5 orbow po 1 XP")

func test_cap_blocks_new_nodes_and_grants_xp() -> void:
	var sp := _make_spawner()
	sp._spawn_orbs(Vector2.ZERO, GameConfig.XP_ORB_MAX_ON_SCREEN, 1)  # wypelnij do capa
	var count_at_cap := get_tree().get_nodes_in_group("xp_orbs").size()
	assert_eq(count_at_cap, GameConfig.XP_ORB_MAX_ON_SCREEN, "liczba orbow ograniczona capem")
	sp._spawn_orbs(Vector2.ZERO, 1, 1)  # nadmiar
	assert_eq(get_tree().get_nodes_in_group("xp_orbs").size(), count_at_cap, "cap: brak nowych wezlow")
	assert_true(GameState.xp > 0 or GameState.level > 1, "nadmiar oddaje XP, nie porzuca nagrody")
