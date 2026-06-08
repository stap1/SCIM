extends GutTest

# #1: power-up co 5 poziom (ZAMIAST zwyklej karty) + harpun przebijajacy.
# Decyzje: power-up zamiast karty na co 5. poziomie; kazdy wybor +1 bez limitu.

const LevelUpScript := preload("res://scripts/ui/level_up.gd")
const HarpoonScript := preload("res://scripts/weapons/harpoon.gd")
const EnemyScript := preload("res://scripts/systems/enemy.gd")
const AutoAttackerScript := preload("res://scripts/systems/auto_attacker.gd")

func before_each() -> void:
	GameState.reset()

# --- Milestone co 5 poziomow ---

func test_is_milestone_level() -> void:
	assert_true(LevelUpScript.is_milestone_level(5, 5), "5 -> milestone")
	assert_true(LevelUpScript.is_milestone_level(10, 5), "10 -> milestone")
	assert_false(LevelUpScript.is_milestone_level(4, 5), "4 -> nie")
	assert_false(LevelUpScript.is_milestone_level(7, 5), "7 -> nie")
	assert_false(LevelUpScript.is_milestone_level(0, 5), "0 -> nie")

func test_milestone_interval_config() -> void:
	assert_eq(GameConfig.MILESTONE_LEVEL_INTERVAL, 5, "co 5 poziomow")

func test_milestone_ids_are_two() -> void:
	var ids := Upgrades.milestone_ids()
	assert_eq(ids.size(), 2, "dwa power-upy milestone")
	assert_true("extra_harpoon" in ids and "piercing" in ids, "harpun + przebijanie")

func test_info_covers_milestone_and_normal() -> void:
	assert_false(Upgrades.info("extra_harpoon").is_empty(), "info dla milestone")
	assert_false(Upgrades.info("faster_attack").is_empty(), "info dla zwyklego")
	assert_true(Upgrades.info("nieistnieje").is_empty(), "info pusty dla nieznanego id")

# --- Stackowanie bez limitu ---

func test_extra_harpoon_stacks_projectiles() -> void:
	var aa = AutoAttackerScript.new()
	add_child_autofree(aa)
	await wait_physics_frames(1)
	var base: int = aa.projectiles_per_attack
	Upgrades.apply("extra_harpoon")
	Upgrades.apply("extra_harpoon")
	assert_eq(aa.projectiles_per_attack, base + 2, "kazdy extra_harpoon +1 (stack bez limitu)")

func test_piercing_stacks_pierce_bonus() -> void:
	var aa = AutoAttackerScript.new()
	add_child_autofree(aa)
	await wait_physics_frames(1)
	Upgrades.apply("piercing")
	Upgrades.apply("piercing")
	assert_eq(aa.pierce_bonus, 2, "kazde przebijanie +1 (stack bez limitu)")

# --- Harpun przebijajacy ---

func _make_enemy() -> Node:
	var e = EnemyScript.new()
	add_child_autofree(e)
	return e

func test_harpoon_pierces_then_deactivates() -> void:
	var h = HarpoonScript.new()
	add_child_autofree(h)
	var a = _make_enemy()
	var b = _make_enemy()
	await wait_physics_frames(1)
	h.fire(Vector2.ZERO, Vector2.RIGHT, 1) # pierce 1 -> przejdzie przez 1 wroga
	h._on_any_collision(a)
	assert_true(h.active, "po 1. trafieniu (pierce=1) harpun leci dalej")
	h._on_any_collision(b)
	assert_false(h.active, "po 2. trafieniu deaktywacja (pierce wyczerpany)")

func test_harpoon_without_pierce_deactivates_on_first() -> void:
	var h = HarpoonScript.new()
	add_child_autofree(h)
	var a = _make_enemy()
	await wait_physics_frames(1)
	h.fire(Vector2.ZERO, Vector2.RIGHT, 0) # bez przebijania (jak dotad)
	h._on_any_collision(a)
	assert_false(h.active, "bez pierce deaktywacja na 1. trafieniu")

func test_harpoon_no_double_hit_same_enemy() -> void:
	var h = HarpoonScript.new()
	add_child_autofree(h)
	var a = _make_enemy()
	await wait_physics_frames(1)
	h.fire(Vector2.ZERO, Vector2.RIGHT, 5)
	var hp0: float = a.health
	h._on_any_collision(a)
	h._on_any_collision(a) # ten sam wrog drugi raz
	assert_almost_eq(a.health, hp0 - h.damage, 0.001, "ten sam wrog trafiony tylko raz na lot")
