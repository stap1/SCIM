extends GutTest

# KROK 15 (Prompt 15) - GATE 1: system 6 upgrade'ow.

func before_each() -> void:
	GameState.reset()

func test_six_upgrades_have_fields() -> void:
	assert_eq(Upgrades.UPGRADES.size(), 6, "slownik ma 6 ulepszen")
	for id in Upgrades.UPGRADES:
		var u = Upgrades.UPGRADES[id]
		assert_true(u.has("id"), "%s ma pole id" % id)
		assert_true(u.has("name"), "%s ma pole name" % id)
		assert_true(u.has("description"), "%s ma pole description" % id)

func test_apply_faster_attack_pure() -> void:
	assert_almost_eq(Upgrades.apply_faster_attack(0.8), 0.72, 0.001, "0.8 * 0.90 = 0.72")

func test_apply_sharper_harpoon_pure() -> void:
	assert_almost_eq(Upgrades.apply_sharper_harpoon(5.0), 7.0, 0.001, "sharper_harpoon: obrazenia +2")

func test_apply_tougher_hull_increases_max_health() -> void:
	var before: float = GameState.max_health
	Upgrades.apply("tougher_hull")
	assert_almost_eq(GameState.max_health, before + 20.0, 0.001, "tougher_hull: max_health +20")

func test_apply_resource_magnet_increases_multiplier() -> void:
	var before: float = GameState.magnet_range_mult
	Upgrades.apply("resource_magnet")
	assert_almost_eq(GameState.magnet_range_mult, before * 1.25, 0.001, "resource_magnet: mnoznik *1.25")

func test_upgrade_respects_max_level() -> void:
	var id := "faster_attack"
	var maxl: int = Upgrades.UPGRADES[id]["max_level"]
	for i in maxl:
		assert_true(id in Upgrades.available_ids(), "przed wyczerpaniem ulepszenie dostepne (i=%d)" % i)
		Upgrades.apply(id)
	assert_false(id in Upgrades.available_ids(), "po max_level ulepszenie znika z puli")
	assert_eq(Upgrades.level_of(id), maxl, "poziom == max_level")

func test_session_reset_clears_levels() -> void:
	Upgrades.apply("tougher_hull")
	assert_eq(Upgrades.level_of("tougher_hull"), 1, "po wyborze poziom 1")
	GameState.reset() # emituje session_reset -> Upgrades.reset_levels
	assert_eq(Upgrades.level_of("tougher_hull"), 0, "session_reset czysci poziomy")
