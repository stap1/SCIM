extends GutTest

# KROK 12 (Prompt 12): XP orb - magnes, zbieranie z guardem, add_xp.

const XpOrbScene := preload("res://scenes/xp_orb.tscn")
const XpOrbScript := preload("res://scripts/systems/xp_orb.gd")
const BoatScene := preload("res://scenes/player/boat.tscn")

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

func test_orb_despawns_after_lifetime() -> void:
	# P0.1: niezebrany orb (brak gracza/poza zasiegiem) znika po lifetime - brak kumulacji.
	var orb = XpOrbScene.instantiate()
	orb.lifetime = 0.05
	add_child_autofree(orb)
	await wait_physics_frames(8)
	assert_false(is_instance_valid(orb), "niezebrany orb znika po uplywie lifetime")

func test_orb_mask_covers_player_layer() -> void:
	# P1.1: po nazwaniu/zmianie warstw orb musi nadal wykrywac cialo gracza (zbieranie).
	var orb = XpOrbScene.instantiate()
	var boat = BoatScene.instantiate()
	assert_ne(orb.collision_mask & boat.collision_layer, 0,
		"maska orba obejmuje warstwe gracza (inaczej orb nie zbierze sie kontaktem)")
	orb.free()
	boat.free()
