extends GutTest

# #4c: pasek HP jako spekany kadlub. Czysta funkcja hull_stage mapuje HP% na etap
# zniszczenia (0 = caly, stages-1 = roztrzaskany) - dobor klatki hull_hp_<stage>.

const HudScript := preload("res://scripts/ui/hud.gd")

func test_full_health_stage_zero() -> void:
	assert_eq(HudScript.hull_stage(100.0, 100.0, 5), 0, "pelne HP -> kadlub caly (etap 0)")

func test_empty_health_max_stage() -> void:
	assert_eq(HudScript.hull_stage(0.0, 100.0, 5), 4, "0 HP -> najbardziej spekany (etap 4)")

func test_stage_thresholds() -> void:
	assert_eq(HudScript.hull_stage(85.0, 100.0, 5), 0, "85% -> etap 0")
	assert_eq(HudScript.hull_stage(70.0, 100.0, 5), 1, "70% -> etap 1")
	assert_eq(HudScript.hull_stage(50.0, 100.0, 5), 2, "50% -> etap 2")
	assert_eq(HudScript.hull_stage(30.0, 100.0, 5), 3, "30% -> etap 3")
	assert_eq(HudScript.hull_stage(10.0, 100.0, 5), 4, "10% -> etap 4")

func test_stage_monotonic_non_decreasing() -> void:
	var prev := 0
	for hp in range(100, -1, -1):
		var s: int = HudScript.hull_stage(float(hp), 100.0, 5)
		assert_true(s >= prev, "etap nie maleje gdy HP spada (hp=%d)" % hp)
		prev = s

func test_guards() -> void:
	assert_eq(HudScript.hull_stage(50.0, 0.0, 5), 0, "max=0 -> etap 0 (guard dzielenia)")
	assert_eq(HudScript.hull_stage(50.0, 100.0, 1), 0, "stages<=1 -> etap 0 (guard)")

func test_overheal_clamps_to_zero() -> void:
	assert_eq(HudScript.hull_stage(150.0, 100.0, 5), 0, "HP > max -> etap 0 (clamp)")
