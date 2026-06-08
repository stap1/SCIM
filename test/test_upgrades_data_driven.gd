extends GutTest

# P2.3: apply() ulepszen jest data-driven - dyspozytornia (id -> Callable) zamiast
# twardego "match id". Dodanie ulepszenia = wpis w katalogu + rejestracja efektu;
# apply() pozostaje nietkniete.

func before_each() -> void:
	GameState.reset()

# --- Spojnosc katalog <-> rejestr efektow ---

func test_every_catalog_entry_has_effect() -> void:
	for id in Upgrades.UPGRADES:
		assert_true(Upgrades.has_effect(id), "zwykle ulepszenie %s ma zarejestrowany efekt" % id)
	for id in Upgrades.MILESTONE_UPGRADES:
		assert_true(Upgrades.has_effect(id), "milestone %s ma zarejestrowany efekt" % id)

func test_no_orphan_effects() -> void:
	# Kazdy zarejestrowany efekt odpowiada wpisowi w katalogu (brak martwych Callable).
	for id in Upgrades.effect_ids():
		assert_true(Upgrades.UPGRADES.has(id) or Upgrades.MILESTONE_UPGRADES.has(id),
			"efekt %s ma wpis w katalogu" % id)

func test_effect_count_matches_catalog() -> void:
	var catalog := Upgrades.UPGRADES.size() + Upgrades.MILESTONE_UPGRADES.size()
	assert_eq(Upgrades.effect_ids().size(), catalog, "liczba efektow == liczba wpisow katalogu")

# --- apply() dyspozytoruje po danych, nie po switchu ---

func test_apply_has_no_hardcoded_switch() -> void:
	var f := FileAccess.open("res://scripts/systems/upgrades.gd", FileAccess.READ)
	assert_not_null(f, "upgrades.gd istnieje")
	if f:
		var src := f.get_as_text()
		f.close()
		assert_false(src.contains("match id"),
			"apply() nie uzywa hardcoded 'match id' (dispatch po rejestrze efektow)")

func test_apply_unknown_id_is_noop() -> void:
	var before: float = GameState.max_health
	Upgrades.apply("nie_istnieje")
	assert_almost_eq(GameState.max_health, before, 0.001, "nieznane id nie robi nic")

# --- Efekty dzialaja tak samo po refaktorze (dispatch przez rejestr) ---

func test_milestone_effect_via_registry() -> void:
	var AutoAttackerScript := load("res://scripts/systems/auto_attacker.gd")
	var aa = AutoAttackerScript.new()
	aa.add_to_group("auto_attacker")
	add_child_autofree(aa)
	await wait_physics_frames(1)
	var base: int = aa.projectiles_per_attack
	Upgrades.apply("extra_harpoon")
	assert_eq(aa.projectiles_per_attack, base + 1, "extra_harpoon przez rejestr: +1 pocisk")

func test_regular_effect_counts_level_via_registry() -> void:
	Upgrades.apply("tougher_hull")
	assert_eq(Upgrades.level_of("tougher_hull"), 1, "zwykle ulepszenie liczy poziom")
