extends GutTest

# KROK 12 (Prompt 12): XP orb - magnes, zbieranie z guardem, add_xp.

const XpOrbScene := preload("res://scenes/xp_orb.tscn")
const XpOrbScript := preload("res://scripts/systems/xp_orb.gd")

func before_each() -> void:
	GameState.reset()

func test_should_magnetize() -> void:
	assert_true(XpOrbScript.should_magnetize(50.0, 120.0), "distance 50 < range 120 -> true")
	assert_false(XpOrbScript.should_magnetize(150.0, 120.0), "distance 150 >= range 120 -> false")

func test_add_xp_increases_and_emits() -> void:
	watch_signals(GameState)
	var before: int = GameState.xp
	GameState.add_xp(3)
	assert_eq(GameState.xp, before + 3, "add_xp(3) zwieksza xp o 3")
	assert_signal_emitted(GameState, "xp_changed", "add_xp emituje xp_changed")

func test_orb_collects_only_once() -> void:
	var orb = XpOrbScene.instantiate()
	add_child_autofree(orb)
	await wait_physics_frames(1)
	var before: int = GameState.xp
	var ov: int = orb.xp_value
	orb._collect()
	orb._collect() # drugie wywolanie - guard is_collected blokuje
	assert_eq(GameState.xp, before + ov, "orb dodaje xp dokladnie raz (guard is_collected)")
	await wait_physics_frames(1)
