extends GutTest

# B5: ekran konca - statystyka zatopien (suma + rozbicie per typ).

const GameOver := preload("res://scripts/ui/game_over.gd")

func test_breakdown_text_contains_total_and_types() -> void:
	var t := GameOver.kills_breakdown_text(12, 8, 3, 1)
	assert_string_contains(t, "Zatopione: 12")
	assert_string_contains(t, "meduzy 8")
	assert_string_contains(t, "barakudy 3")
	assert_string_contains(t, "rekiny 1")

func test_breakdown_text_zeros() -> void:
	var t := GameOver.kills_breakdown_text(0, 0, 0, 0)
	assert_string_contains(t, "Zatopione: 0")
	assert_string_contains(t, "meduzy 0")
