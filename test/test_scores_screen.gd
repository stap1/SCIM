extends GutTest

# P2.6: ekran najlepszych wynikow (scripts/ui/scores.gd).
# Budowanie tekstu listy wydzielone do czystej funkcji; smoke sceny.

const ScoresScene := preload("res://scenes/Scores.tscn")
const ScoresScript := preload("res://scripts/ui/scores.gd")

func test_format_scores_empty() -> void:
	assert_eq(ScoresScript.format_scores([]), "Brak wyników",
		"pusta lista -> komunikat zastepczy")

func test_format_scores_numbered_descending() -> void:
	var txt := ScoresScript.format_scores([
		{"name": "Ala", "score": 30}, {"name": "Bob", "score": 20}, {"name": "Cy", "score": 10},
	])
	assert_true(txt.contains("1.") and txt.contains("Ala") and txt.contains("30"), "1. miejsce = Ala 30")
	assert_true(txt.contains("2.") and txt.contains("Bob") and txt.contains("20"), "2. miejsce = Bob 20")
	assert_true(txt.contains("3.") and txt.contains("Cy") and txt.contains("10"), "3. miejsce = Cy 10")

func test_scores_smoke_loads() -> void:
	var s = ScoresScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	assert_true(is_instance_valid(s), "Scores.tscn laduje bez crasha")
