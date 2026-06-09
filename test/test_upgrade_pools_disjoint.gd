extends GutTest

# QA #3: specjalne ulepszenia (milestone) NIE moga pojawiac sie w zwyklym level upie.
# Gwarancja jest strukturalna: pule sa rozlaczne, a level_up dobiera je jedna funkcja.

const LevelUpScript := preload("res://scripts/ui/level_up.gd")

func before_each() -> void:
	GameState.reset()

# --- Rozlacznosc katalogow (zrodlo izolacji) ---

func test_regular_and_milestone_pools_are_disjoint() -> void:
	for id in Upgrades.UPGRADES:
		assert_false(Upgrades.MILESTONE_UPGRADES.has(id),
			"id '%s' nie moze byc jednoczesnie zwykly i milestone" % id)

func test_available_ids_never_contains_milestone() -> void:
	for id in Upgrades.available_ids():
		assert_false(Upgrades.MILESTONE_UPGRADES.has(id),
			"zwykla pula losowania nie moze zawierac power-upu milestone")

# --- pick_n: uogolniony dobor (zastepuje pick_three) ---

func test_pick_n_returns_count_unique() -> void:
	var pool: Array[String] = ["a", "b", "c", "d", "e"]
	var r := LevelUpScript.pick_n(pool, 123, 3)
	assert_eq(r.size(), 3, "pick_n(.., 3) zwraca 3 opcje")
	assert_eq(r, _unique(r), "opcje sa unikalne")

func test_pick_n_clamps_to_pool_size() -> void:
	var pool: Array[String] = ["x", "y"]
	assert_eq(LevelUpScript.pick_n(pool, 1, 3).size(), 2, "nie wiecej niz dlugosc puli")

func test_pick_n_deterministic() -> void:
	var pool: Array[String] = ["a", "b", "c", "d"]
	assert_eq(LevelUpScript.pick_n(pool, 42, 3), LevelUpScript.pick_n(pool, 42, 3),
		"ten sam seed -> ten sam wynik")

func _unique(arr: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for v in arr:
		if v not in out:
			out.append(v)
	return out
