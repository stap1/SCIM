extends GutTest

# KROK 17 (Prompt 17): krzywa trudnosci - current_tier + dane difficulty_curve.

const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func test_current_tier() -> void:
	var keys: Array[int] = [0, 1, 2, 3]
	assert_eq(SpawnerScript.current_tier(0, keys), 0, "0s -> tier 0")
	assert_eq(SpawnerScript.current_tier(90, keys), 1, "90s (minuta 1) -> tier 1")
	assert_eq(SpawnerScript.current_tier(200, keys), 3, "200s (minuta 3) -> tier 3")

func test_difficulty_curve_has_tier_zero() -> void:
	var spawner = SpawnerScript.new()
	assert_true(spawner.difficulty_curve.has(0), "krzywa zawiera klucz 0")
	var entry = spawner.difficulty_curve[0]
	assert_true(entry["enemies"].size() > 0, "tier 0 ma niepusta liste wrogow")
	spawner.free()

func test_spawn_interval_monotonic_non_increasing() -> void:
	var spawner = SpawnerScript.new()
	var keys = spawner.difficulty_curve.keys()
	keys.sort()
	var prev := INF
	for k in keys:
		var si: float = spawner.difficulty_curve[k]["spawn_interval"]
		assert_true(si <= prev, "spawn_interval nierosnacy (minuta %d: %.2f <= %.2f)" % [k, si, prev])
		prev = si
	spawner.free()
