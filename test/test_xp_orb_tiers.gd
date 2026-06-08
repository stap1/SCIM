extends GutTest

# #2: mocniejsi wrogowie zrzucaja wartosciowsze orby XP.
# Meduza 1 (baza, GameConfig), barakuda 2, rekin 5 (scena), mini-boss 10 (GameConfig).

const EnemyScript := preload("res://scripts/systems/enemy.gd")
const BarracudaScene := preload("res://scenes/enemies/barracuda.tscn")
const SharkScene := preload("res://scenes/enemies/shark.tscn")
const XpOrbScene := preload("res://scenes/xp_orb.tscn")

func before_each() -> void:
	GameState.reset()

func test_config_tier_values() -> void:
	assert_eq(GameConfig.XP_ORB_VALUE, 1, "baza (meduza) = 1")
	assert_eq(GameConfig.XP_ORB_MINIBOSS, 10, "mini-boss = 10")

func test_jellyfish_base_xp_value() -> void:
	var e = EnemyScript.new()
	assert_eq(e.xp_value, GameConfig.XP_ORB_VALUE, "meduza xp_value = baza z GameConfig")
	e.free()

func test_barracuda_and_shark_xp_values() -> void:
	var b = BarracudaScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	assert_eq(b.xp_value, 2, "barakuda zrzuca orb x2")
	var s = SharkScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	assert_eq(s.xp_value, 5, "rekin zrzuca orb x5")

func test_died_signal_carries_xp_value() -> void:
	var b = BarracudaScene.instantiate()
	add_child(b)
	await wait_physics_frames(1)
	watch_signals(b)
	b.die()
	var params = get_signal_parameters(b, "died")
	assert_eq(params[0], b.global_position, "died niesie pozycje")
	assert_eq(params[1], 2, "died niesie xp_value (barakuda 2)")
	await wait_physics_frames(1)

func test_orb_grants_its_own_xp_value() -> void:
	var orb = XpOrbScene.instantiate()
	orb.xp_value = 5
	add_child_autofree(orb)
	await wait_physics_frames(1)
	var before: int = GameState.xp
	orb._collect()
	assert_eq(GameState.xp, before + 5, "orb przyznaje swoj xp_value (5)")
	await wait_physics_frames(1)
