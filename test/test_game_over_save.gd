extends GutTest

# Zapis wyniku z ekranu konca gry: guard podwojnego zapisu (_score_saved) + auto-zapis
# przy wyjsciu (restart/menu) - zaden wynik nie ginie. Puste pole pseudonimu -> DEFAULT_NAME.
# Sciezka pliku injectowana (highscores_path), by testy nie dotykaly prawdziwej tablicy.

const GameOverScene := preload("res://scenes/ui/game_over.tscn")
const HighScores := preload("res://scripts/systems/highscores.gd")
const TEST_PATH := "user://test_go_save.cfg"

var go

func before_each() -> void:
	HighScores.clear(TEST_PATH)
	GameState.reset()
	go = GameOverScene.instantiate()
	go.highscores_path = TEST_PATH
	add_child_autofree(go)
	await wait_physics_frames(1)

func after_each() -> void:
	get_tree().paused = false # kontroler pauzuje na game_over - przywroc po tescie
	GameState.reset()

func _scores(list: Array) -> Array:
	return list.map(func(e): return int(e["score"]))

func test_save_pressed_writes_exactly_once() -> void:
	GameState.add_score(50)
	GameState.trigger_game_over(false)
	await wait_frames(1)
	go._on_save_pressed()
	go._on_save_pressed() # klik + Enter albo dwuklik - guard musi trzymac
	var top := HighScores.get_top(5, TEST_PATH)
	assert_eq(top.size(), 1, "guard _score_saved: dokladnie jeden wpis")
	assert_eq(int(top[0]["score"]), 50, "zapisany biezacy wynik")

func test_exit_without_save_autosaves_as_default_name() -> void:
	GameState.add_score(30)
	GameState.trigger_game_over(false)
	await wait_frames(1)
	go._save_score_if_needed() # wspolna sciezka restart/menu (bez klikniecia ZAPISZ)
	var top := HighScores.get_top(5, TEST_PATH)
	assert_eq(top.size(), 1, "wyjscie bez klikniecia ZAPISZ tez utrwala wynik")
	assert_eq(top[0]["name"], HighScores.DEFAULT_NAME, "puste pole pseudonimu -> nazwa zastepcza")
	assert_eq(int(top[0]["score"]), 30, "zapisany biezacy wynik")

func test_second_game_over_resets_guard() -> void:
	GameState.add_score(10)
	GameState.trigger_game_over(false)
	await wait_frames(1)
	go._on_save_pressed()
	get_tree().paused = false
	GameState.reset()
	GameState.add_score(20)
	GameState.trigger_game_over(false)
	await wait_frames(1)
	go._on_save_pressed()
	assert_eq(_scores(HighScores.get_top(5, TEST_PATH)), [20, 10],
		"drugi koniec gry w tej samej sesji zapisuje ponownie (guard zresetowany)")

func test_exit_buttons_wired() -> void:
	assert_true(go.restart_button.pressed.is_connected(go._on_restart_pressed),
		"restart podpiety pod handler z auto-zapisem")
	assert_true(go.menu_button.pressed.is_connected(go._on_menu_pressed),
		"menu podpiete pod handler z auto-zapisem")
