extends GutTest

# High scores: czysta insert_score (wpisy {name, score}) + round-trip ConfigFile.

const HighScores := preload("res://scripts/systems/highscores.gd")

func _scores(list: Array) -> Array:
	return list.map(func(e): return int(e["score"]))

func test_insert_score_sorts_descending() -> void:
	var list: Array = [{"name": "A", "score": 10}, {"name": "B", "score": 5}]
	var r := HighScores.insert_score(list, "C", 7, 5)
	assert_eq(_scores(r), [10, 7, 5], "sortuje malejaco po wyniku")

func test_insert_score_trims_to_max() -> void:
	var list: Array = [
		{"name": "a", "score": 50}, {"name": "b", "score": 40},
		{"name": "c", "score": 30}, {"name": "d", "score": 20}, {"name": "e", "score": 10},
	]
	var r := HighScores.insert_score(list, "x", 35, 5)
	assert_eq(r.size(), 5, "przyciete do max 5")
	assert_eq(_scores(r), [50, 40, 35, 30, 20], "zostaje 5 najlepszych wynikow")

func test_insert_score_keeps_name_with_score() -> void:
	var r := HighScores.insert_score([], "Stanisław", 100, 5)
	assert_eq(r[0]["name"], "Stanisław", "nazwa zapisana z wynikiem")
	assert_eq(r[0]["score"], 100, "wynik zapisany")

func test_config_round_trip() -> void:
	var path := "user://test_highscores.cfg"
	HighScores.clear(path)
	HighScores.add_score("A", 10, path)
	HighScores.add_score("B", 30, path)
	HighScores.add_score("C", 20, path)
	var top := HighScores.get_top(5, path)
	assert_eq(_scores(top), [30, 20, 10], "get_top zwraca posortowane malejaco")
	assert_eq(top[0]["name"], "B", "nazwa zachowana w round-trip")

func test_get_top_empty_no_crash() -> void:
	var path := "user://test_highscores_empty.cfg"
	HighScores.clear(path)
	assert_eq(HighScores.get_top(5, path), [], "pusta tablica bez crasha")
