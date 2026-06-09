extends GutTest

# P2.9: walidacja wczytanych high scores. Uszkodzony/zewnetrzny plik configu moze
# zawierac cokolwiek pod "scores/top" - get_top nie moze crashowac ani wpuszczac smieci.

const HighScores := preload("res://scripts/systems/highscores.gd")

# --- Czysta funkcja sanitize_scores ---

func test_sanitize_rejects_non_array() -> void:
	assert_eq(HighScores.sanitize_scores(42), [] as Array[int], "int -> []")
	assert_eq(HighScores.sanitize_scores("nie tablica"), [] as Array[int], "String -> []")
	assert_eq(HighScores.sanitize_scores(null), [] as Array[int], "null -> []")
	assert_eq(HighScores.sanitize_scores({"a": 1}), [] as Array[int], "Dictionary -> []")

func test_sanitize_keeps_numbers_drops_junk() -> void:
	var raw := [5, "7", 9.0, "abc", {}, null, true]
	assert_eq(HighScores.sanitize_scores(raw), [5, 7, 9] as Array[int],
		"zachowuje liczby i valid-int stringi, pomija smieci")

func test_sanitize_empty_array() -> void:
	assert_eq(HighScores.sanitize_scores([]), [] as Array[int], "pusta tablica -> []")

# --- get_top odporne na uszkodzony config ---

func test_get_top_corrupted_not_array_no_crash() -> void:
	var path := "user://test_hs_corrupt.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", "to nie jest tablica")
	cfg.save(path)
	assert_eq(HighScores.get_top(5, path), [] as Array[int],
		"uszkodzony config (nie-Array) -> pusta lista bez crasha")

func test_get_top_skips_non_numeric_entries() -> void:
	var path := "user://test_hs_mixed.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", [30, "20", 10.0, "abc", null])
	cfg.save(path)
	assert_eq(HighScores.get_top(5, path), [30, 20, 10] as Array[int],
		"pomija wpisy nieliczbowe, zachowuje liczby (malejaco)")

func test_add_score_after_corruption_recovers() -> void:
	var path := "user://test_hs_recover.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", 12345) # smieci
	cfg.save(path)
	HighScores.add_score(50, path) # nie moze crashowac na wczytaniu smieci
	assert_eq(HighScores.get_top(5, path), [50] as Array[int],
		"add_score po uszkodzeniu odbudowuje poprawna tablice")
