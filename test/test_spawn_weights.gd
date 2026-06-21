extends GutTest

# R5: spawn wagowy (budzet rosnacy, wazone losowanie, skracany interwal) i XP x2.

const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func before_each() -> void:
	GameState.reset()

# --- Budzet wagi na ekranie ---
func test_weight_budget_grows_and_caps() -> void:
	var base := SpawnerScript.weight_budget(0.0, 0.0)
	assert_almost_eq(base, GameConfig.ENEMY_WEIGHT_BUDGET_BASE, 0.001, "t=0 -> BASE")
	var later := SpawnerScript.weight_budget(120.0, 0.0)
	assert_true(later > base, "budzet rosnie z czasem")
	var capped := SpawnerScript.weight_budget(100000.0, 0.0)
	assert_almost_eq(capped, GameConfig.ENEMY_WEIGHT_BUDGET_MAX, 0.001, "budzet capowany do MAX")

func test_weight_budget_horde_bonus_raises() -> void:
	var normal := SpawnerScript.weight_budget(0.0, 0.0)
	var boosted := SpawnerScript.weight_budget(0.0, 6.0)
	assert_almost_eq(boosted, normal + 6.0, 0.001, "horda dodaje wrogow ponad budzet")
	# Dziala takze gdy bazowy budzet jest juz na capie (dodatek ponad MAX - wazne dla late game).
	var late := SpawnerScript.weight_budget(100000.0, 6.0)
	assert_almost_eq(late, GameConfig.ENEMY_WEIGHT_BUDGET_MAX + 6.0, 0.001, "horda dodaje tez na capie")

# --- Wazone losowanie ---
func test_weighted_pick_respects_weights() -> void:
	var w: Array[int] = [1, 2, 3]  # total 6
	assert_eq(SpawnerScript.weighted_pick(w, 0.1), 0, "0.6/6 -> idx0")
	assert_eq(SpawnerScript.weighted_pick(w, 0.3), 1, "1.8/6 -> idx1")
	assert_eq(SpawnerScript.weighted_pick(w, 0.9), 2, "5.4/6 -> idx2")

func test_weighted_pick_empty() -> void:
	assert_eq(SpawnerScript.weighted_pick([] as Array[int], 0.5), -1, "pusta -> -1")
	assert_eq(SpawnerScript.weighted_pick([0, 0] as Array[int], 0.5), -1, "zerowe wagi -> -1")

# --- Interwal spawnu ---
func test_spawn_interval_shrinks() -> void:
	assert_almost_eq(SpawnerScript.spawn_interval_for(0.0, 1.0), 1.0, 0.001, "t=0 -> baza")
	assert_true(SpawnerScript.spawn_interval_for(120.0, 1.0) < 1.0, "interwal maleje z czasem")
	var floor_v := SpawnerScript.spawn_interval_for(100000.0, 1.0)
	assert_almost_eq(floor_v, GameConfig.SPAWN_INTERVAL_MIN_FACTOR, 0.001, "interwal capowany do MIN_FACTOR")

# --- XP x2 ---
func test_xp_drop_mult_const() -> void:
	assert_eq(GameConfig.XP_ORB_DROP_MULT, 2, "mnoznik zrzutu orbow = 2")

func test_enemy_death_drops_double_orbs() -> void:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var spawner = SpawnerScript.new()
	parent.add_child(spawner)
	await wait_physics_frames(1)
	# Wrog wart xp_value=2 -> 2 * mult(2) = 4 orby.
	spawner._on_enemy_died(Vector2.ZERO, 2, Enemy.EnemyType.JELLYFISH)
	await wait_physics_frames(1)
	var count := 0
	for o in get_tree().get_nodes_in_group("xp_orbs"):
		if is_instance_valid(o) and o.get_parent() == parent:
			count += 1
	assert_eq(count, 4, "xp_value 2 * mult 2 = 4 orby")
