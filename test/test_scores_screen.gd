extends GutTest

# P2.6: ekran najlepszych wynikow (scripts/ui/scores.gd).
# Budowanie tekstu listy wydzielone do czystej funkcji; smoke sceny.

const ScoresScene := preload("res://scenes/Scores.tscn")
const ScoresScript := preload("res://scripts/ui/scores.gd")

func test_format_scores_empty() -> void:
	assert_eq(ScoresScript.format_scores([] as Array[int]), "Brak wyników",
		"pusta lista -> komunikat zastepczy")

func test_format_scores_numbered_descending() -> void:
	var txt := ScoresScript.format_scores([30, 20, 10] as Array[int])
	assert_true(txt.contains("1.") and txt.contains("30"), "1. miejsce = 30")
	assert_true(txt.contains("2.") and txt.contains("20"), "2. miejsce = 20")
	assert_true(txt.contains("3.") and txt.contains("10"), "3. miejsce = 10")

func test_scores_smoke_loads() -> void:
	var s = ScoresScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	assert_true(is_instance_valid(s), "Scores.tscn laduje bez crasha")
