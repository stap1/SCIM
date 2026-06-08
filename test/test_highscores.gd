extends GutTest

# KROK 21 (Prompt 21): high scores - czysta insert_score + round-trip ConfigFile.

const HighScores := preload("res://scripts/systems/highscores.gd")

func test_insert_score_sorts_descending() -> void:
	var list: Array[int] = [10, 5]
	assert_eq(HighScores.insert_score(list, 7, 5), [10, 7, 5], "sortuje malejaco")

func test_insert_score_trims_to_max() -> void:
	var list: Array[int] = [50, 40, 30, 20, 10]
	var r := HighScores.insert_score(list, 35, 5)
	assert_eq(r.size(), 5, "przyciete do max 5")
	assert_eq(r, [50, 40, 35, 30, 20], "zostaje 5 najlepszych")

func test_config_round_trip() -> void:
	var path := "user://test_highscores.cfg"
	HighScores.clear(path)
	HighScores.add_score(10, path)
	HighScores.add_score(30, path)
	HighScores.add_score(20, path)
	assert_eq(HighScores.get_top(5, path), [30, 20, 10], "get_top zwraca posortowane malejaco")

func test_get_top_empty_no_crash() -> void:
	var path := "user://test_highscores_empty.cfg"
	HighScores.clear(path)
	assert_eq(HighScores.get_top(5, path), [], "pusta tablica bez crasha")
