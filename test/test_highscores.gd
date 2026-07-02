extends GutTest

# High scores: czysta insert_score (wpisy {name, score}) + round-trip ConfigFile.
# Remisy: sortowanie stabilne - istniejace wpisy maja pierwszenstwo przed nowym.

const HighScores := preload("res://scripts/systems/highscores.gd")

func _scores(list: Array) -> Array:
	return list.map(func(e): return int(e["score"]))

func test_insert_score_sorts_descending() -> void:
	var list: Array[Dictionary] = [{"name": "A", "score": 10}, {"name": "B", "score": 5}]
	var r := HighScores.insert_score(list, "C", 7, 5)
	assert_eq(_scores(r), [10, 7, 5], "sortuje malejaco po wyniku")

func test_insert_score_trims_to_max() -> void:
	var list: Array[Dictionary] = [
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

func test_insert_score_tie_keeps_existing_first() -> void:
	# Remis wynikow: niestabilny sort_custom Godota nie moze decydowac o kolejnosci -
	# tiebreak po pozycji wejsciowej gwarantuje, ze istniejacy (starszy) wpis stoi wyzej.
	var list: Array[Dictionary] = [{"name": "Stary", "score": 100}]
	var r := HighScores.insert_score(list, "Nowy", 100, 5)
	assert_eq(r[0]["name"], "Stary", "remis: istniejacy wpis wyzej")
	assert_eq(r[1]["name"], "Nowy", "remis: nowy wpis za istniejacym")

func test_insert_score_tie_on_full_board_evicts_new() -> void:
	var list: Array[Dictionary] = []
	for n in ["a", "b", "c", "d", "e"]:
		list.append({"name": n, "score": 100})
	var r := HighScores.insert_score(list, "f", 100, 5)
	assert_eq(r.size(), 5, "przyciete do 5")
	assert_eq(r.map(func(e): return e["name"]), ["a", "b", "c", "d", "e"],
		"remis na pelnej tablicy: nowy wpis odpada, kolejnosc starych bez zmian")

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
	assert_eq(HighScores.get_top(5, path), [] as Array[Dictionary], "pusta tablica bez crasha")

func test_get_top_nonpositive_n_returns_empty() -> void:
	var path := "user://test_hs_nonpositive.cfg"
	HighScores.clear(path)
	HighScores.add_score("A", 10, path)
	assert_eq(HighScores.get_top(0, path), [] as Array[Dictionary], "n=0 -> pusta lista")
	assert_eq(HighScores.get_top(-1, path), [] as Array[Dictionary],
		"n<0 -> pusta lista (nie 'size-1' ze slice z ujemnym koncem)")
