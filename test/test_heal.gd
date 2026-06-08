extends GutTest

# #4: leczenie - dryfujaca deska (heal pickup) + pelne HP na awansie poziomu.

const HealPlankScene := preload("res://scenes/heal_plank.tscn")

func before_each() -> void:
	GameState.reset()

func test_heal_adds_clamped() -> void:
	GameState.health = 50.0
	GameState.heal(25.0)
	assert_almost_eq(GameState.health, 75.0, 0.001, "heal(25) z 50 -> 75")

func test_heal_never_exceeds_max() -> void:
	GameState.health = 90.0
	GameState.heal(1000.0)
	assert_almost_eq(GameState.health, GameState.max_health, 0.001, "heal nie przekracza max_health")

func test_heal_to_full() -> void:
	GameState.health = 10.0
	GameState.heal_to_full()
	assert_almost_eq(GameState.health, GameState.max_health, 0.001, "heal_to_full -> max")

func test_level_up_heals_to_full() -> void:
	GameState.health = 10.0
	GameState.add_xp(20) # awans 1 -> 2
	assert_eq(GameState.level, 2, "awans nastapil")
	assert_almost_eq(GameState.health, GameState.max_health, 0.001, "awans leczy do pelna")

func test_boss_reward_heals_to_full() -> void:
	GameState.health = 10.0
	GameState.grant_level_up()
	assert_almost_eq(GameState.health, GameState.max_health, 0.001, "nagroda bossa leczy do pelna")

func test_no_heal_without_level_up() -> void:
	# add_xp ponizej progu nie awansuje -> nie leczy.
	GameState.health = 30.0
	GameState.add_xp(1) # threshold(1)=10, brak awansu
	assert_almost_eq(GameState.health, 30.0, 0.001, "brak awansu -> brak leczenia")

func test_plank_config() -> void:
	assert_almost_eq(GameConfig.HEAL_PLANK_AMOUNT, 25.0, 0.001, "deska +25 HP")

func test_plank_heals_on_collect() -> void:
	GameState.health = 40.0
	var p = HealPlankScene.instantiate()
	add_child_autofree(p)
	await wait_physics_frames(1)
	p._collect()
	assert_almost_eq(GameState.health, 40.0 + GameConfig.HEAL_PLANK_AMOUNT, 0.001,
		"deska leczy o HEAL_PLANK_AMOUNT")
	await wait_physics_frames(1)

func test_plank_collect_once() -> void:
	GameState.health = 40.0
	var p = HealPlankScene.instantiate()
	add_child_autofree(p)
	await wait_physics_frames(1)
	p._collect()
	p._collect() # guard is_collected
	assert_almost_eq(GameState.health, 40.0 + GameConfig.HEAL_PLANK_AMOUNT, 0.001,
		"podwojny collect leczy tylko raz")
	await wait_physics_frames(1)
