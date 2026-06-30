extends GutTest

# Walidacja wczytanych high scores. Uszkodzony/zewnetrzny plik configu moze zawierac
# cokolwiek pod "scores/top" - get_top nie moze crashowac ani wpuszczac smieci.

const HighScores := preload("res://scripts/systems/highscores.gd")

func _scores(list: Array) -> Array:
	return list.map(func(e): return int(e["score"]))

# --- Czysta funkcja sanitize_entries ---

func test_sanitize_rejects_non_array() -> void:
	assert_eq(HighScores.sanitize_entries(42), [], "int -> []")
	assert_eq(HighScores.sanitize_entries("nie tablica"), [], "String -> []")
	assert_eq(HighScores.sanitize_entries(null), [], "null -> []")
	assert_eq(HighScores.sanitize_entries({"a": 1}), [], "Dictionary -> []")

func test_sanitize_keeps_valid_drops_junk() -> void:
	var raw := [{"name": "A", "score": 5}, {"name": "B", "score": "7"}, 9, "abc", {}, null, true]
	var out := HighScores.sanitize_entries(raw)
	assert_eq(_scores(out), [5, 7, 9], "zachowuje poprawne wpisy/liczby, pomija smieci")

func test_sanitize_old_int_format_gets_default_name() -> void:
	var out := HighScores.sanitize_entries([42])
	assert_eq(out[0]["score"], 42, "stary format - wynik zachowany")
	assert_eq(out[0]["name"], HighScores.DEFAULT_NAME, "stary format - nazwa zastepcza")

func test_sanitize_empty_array() -> void:
	assert_eq(HighScores.sanitize_entries([]), [], "pusta tablica -> []")

# --- Czysta funkcja sanitize_name ---

func test_sanitize_name_caps_length() -> void:
	var long_name := "ABCDEFGHIJKLMNOPQRSTUVWXYZ" # 26 znakow
	assert_eq(HighScores.sanitize_name(long_name).length(), HighScores.NAME_MAX_LEN, "nazwa przycieta do 20")

func test_sanitize_name_strips_and_defaults() -> void:
	assert_eq(HighScores.sanitize_name("   "), HighScores.DEFAULT_NAME, "puste/biale -> nazwa zastepcza")
	assert_eq(HighScores.sanitize_name("Jan\nKowalski"), "Jan Kowalski", "nowa linia -> spacja")

# --- get_top odporne na uszkodzony config ---

func test_get_top_corrupted_not_array_no_crash() -> void:
	var path := "user://test_hs_corrupt.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", "to nie jest tablica")
	cfg.save(path)
	assert_eq(HighScores.get_top(5, path), [], "uszkodzony config (nie-Array) -> pusta lista bez crasha")

func test_get_top_skips_non_numeric_entries() -> void:
	var path := "user://test_hs_mixed.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", [{"name": "A", "score": 30}, {"name": "B", "score": "20"}, 10, "abc", null])
	cfg.save(path)
	assert_eq(_scores(HighScores.get_top(5, path)), [30, 20, 10],
		"pomija wpisy nieliczbowe, zachowuje liczby (malejaco)")

func test_add_score_after_corruption_recovers() -> void:
	var path := "user://test_hs_recover.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", 12345) # smieci
	cfg.save(path)
	HighScores.add_score("Z", 50, path) # nie moze crashowac na wczytaniu smieci
	var top := HighScores.get_top(5, path)
	assert_eq(_scores(top), [50], "add_score po uszkodzeniu odbudowuje poprawna tablice")
	assert_eq(top[0]["name"], "Z", "nazwa zachowana po odbudowie")
