extends GutTest

# REGRESJA #4: brak inkrementacji czasu w HUD - czas tylko w jednym miejscu (krok 7).
# HUD jest read-only. Czas inkrementuje WYLACZNIE main.gd. Skanujemy zrodla,
# bo to jedyny pewny sposob wychwycic ponowne wprowadzenie podwojnego liczenia.

func _read_source(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		fail_test("Nie mozna otworzyc pliku: " + path)
		return ""
	var content := f.get_as_text()
	f.close()
	return content

func test_hud_does_not_increment_time() -> void:
	var src := _read_source("res://scripts/ui/hud.gd")
	assert_true(src.find("GameState.time +=") == -1,
		"HUD nie moze inkrementowac czasu (GameState.time += ...) - to read-only")
	assert_true(src.find("GameState.add_time") == -1,
		"HUD nie moze wywolywac add_time - czas liczy tylko main.gd")

func test_time_counted_in_main() -> void:
	var src := _read_source("res://scripts/systems/main.gd")
	assert_true(src.find("GameState.time +=") != -1,
		"Czas musi byc liczony w main.gd (jedyne miejsce inkrementacji czasu)")
