extends GutTest

# Walidacja wczytanych high scores. Uszkodzony/zewnetrzny plik configu moze zawierac
# cokolwiek pod "scores/top" - get_top nie moze crashowac ani wpuszczac smieci.

const HighScores := preload("res://scripts/systems/highscores.gd")

func _scores(list: Array) -> Array:
	return list.map(func(e): return int(e["score"]))

# --- Czysta funkcja sanitize_entries ---

func test_sanitize_rejects_non_array() -> void:
	assert_eq(HighScores.sanitize_entries(42), [] as Array[Dictionary], "int -> []")
	assert_eq(HighScores.sanitize_entries("nie tablica"), [] as Array[Dictionary], "String -> []")
	assert_eq(HighScores.sanitize_entries(null), [] as Array[Dictionary], "null -> []")
	assert_eq(HighScores.sanitize_entries({"a": 1}), [] as Array[Dictionary], "Dictionary -> []")

func test_sanitize_keeps_valid_drops_junk() -> void:
	var raw := [{"name": "A", "score": 5}, {"name": "B", "score": "7"}, 9, "abc", {}, null, true]
	var out := HighScores.sanitize_entries(raw)
	assert_eq(_scores(out), [5, 7, 9], "zachowuje poprawne wpisy/liczby, pomija smieci")

func test_sanitize_old_int_format_gets_default_name() -> void:
	var out := HighScores.sanitize_entries([42])
	assert_eq(out[0]["score"], 42, "stary format - wynik zachowany")
	assert_eq(out[0]["name"], HighScores.DEFAULT_NAME, "stary format - nazwa zastepcza")

func test_sanitize_empty_array() -> void:
	assert_eq(HighScores.sanitize_entries([]), [] as Array[Dictionary], "pusta tablica -> []")

func test_sanitize_entries_rejects_inf_nan() -> void:
	# VariantParser configu akceptuje literaly inf/nan - int(inf) daje smieciowy sentinel,
	# wiec takie "wyniki" musza odpasc juz na sanitizacji.
	var raw := [{"name": "X", "score": INF}, {"name": "Y", "score": -INF},
		{"name": "N", "score": NAN}, {"name": "Z", "score": 5}]
	assert_eq(_scores(HighScores.sanitize_entries(raw)), [5], "inf/nan odrzucone, skonczone wyniki zostaja")

# --- Czysta funkcja sanitize_name ---

func test_sanitize_name_caps_length() -> void:
	var long_name := "ABCDEFGHIJKLMNOPQRSTUVWXYZ" # 26 znakow
	assert_eq(HighScores.sanitize_name(long_name).length(), HighScores.NAME_MAX_LEN, "nazwa przycieta do 20")

func test_sanitize_name_strips_and_defaults() -> void:
	assert_eq(HighScores.sanitize_name("   "), HighScores.DEFAULT_NAME, "puste/biale -> nazwa zastepcza")
	assert_eq(HighScores.sanitize_name("Jan\nKowalski"), "Jan Kowalski", "nowa linia -> spacja")

func test_sanitize_name_idempotent_after_truncation() -> void:
	# 19 znakow + spacja + X: przyciecie do 20 konczyloby sie spacja, ktora kolejny
	# odczyt by obcial - nazwa nie moze mutowac przy ponownej sanitizacji.
	var raw := "AAAAAAAAAAAAAAAAAAA X"
	var once := HighScores.sanitize_name(raw)
	assert_eq(HighScores.sanitize_name(once), once, "sanitize_name(sanitize_name(x)) == sanitize_name(x)")
	assert_eq(once, once.strip_edges(), "wynik bez bialych znakow na koncach")

func test_sanitize_name_invisible_only_falls_back_to_default() -> void:
	assert_eq(HighScores.sanitize_name(char(0x00A0).repeat(3)), HighScores.DEFAULT_NAME,
		"same twarde spacje (NBSP) -> nazwa zastepcza, nie niewidzialny wpis")
	assert_eq(HighScores.sanitize_name(char(0x200B) + char(0xFEFF)), HighScores.DEFAULT_NAME,
		"znaki zero-width -> nazwa zastepcza")
	assert_eq(HighScores.sanitize_name(char(127) + char(150)), HighScores.DEFAULT_NAME,
		"DEL i znaki sterujace C1 -> nazwa zastepcza")

func test_sanitize_name_nbsp_inside_becomes_space() -> void:
	assert_eq(HighScores.sanitize_name("Jan" + char(0x00A0) + "Kowalski"), "Jan Kowalski",
		"NBSP w srodku -> zwykla spacja")

func test_sanitize_name_huge_input_capped() -> void:
	# Zlosliwie dlugi string z uszkodzonego pliku nie moze kosztowac O(n^2) -
	# surowe wejscie jest sciete twardym limitem przed petla.
	var huge := "B".repeat(100000)
	assert_eq(HighScores.sanitize_name(huge), "B".repeat(HighScores.NAME_MAX_LEN),
		"gigantyczne wejscie -> po prostu 20 znakow")

# --- get_top odporne na uszkodzony config ---

func test_get_top_corrupted_not_array_no_crash() -> void:
	var path := "user://test_hs_corrupt.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", "to nie jest tablica")
	cfg.save(path)
	assert_eq(HighScores.get_top(5, path), [] as Array[Dictionary],
		"uszkodzony config (nie-Array) -> pusta lista bez crasha")

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
