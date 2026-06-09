extends GutTest

# P2.6: kontroler ekranu game over (scripts/ui/game_over.gd).
# Logika rekordu wydzielona do czystych funkcji; smoke + wiring sceny.

const GameOverScene := preload("res://scenes/ui/game_over.tscn")
const GameOverScript := preload("res://scripts/ui/game_over.gd")

func after_each() -> void:
	get_tree().paused = false # kontroler pauzuje na game_over - przywroc po tescie
	GameState.reset()

# --- Czysta logika rekordu ---

func test_is_new_record_pure() -> void:
	assert_true(GameOverScript.is_new_record(100, 50), "wynik > best -> rekord")
	assert_true(GameOverScript.is_new_record(100, 100), "wynik == best -> rekord (>=)")
	assert_false(GameOverScript.is_new_record(40, 50), "wynik < best -> nie")
	assert_false(GameOverScript.is_new_record(0, 0), "wynik 0 -> nie (pusty przebieg)")

func test_best_text_marks_record() -> void:
	assert_true(GameOverScript.best_text(120, true).contains("REKORD"), "rekord oznaczony")
	assert_false(GameOverScript.best_text(120, false).contains("REKORD"), "bez rekordu brak oznaczenia")
	assert_true(GameOverScript.best_text(120, false).contains("120"), "pokazuje wartosc najlepszego")

# --- Scena: laduje i podpina sie pod game_over ---

func test_controller_connects_game_over() -> void:
	var go = GameOverScene.instantiate()
	add_child_autofree(go)
	await wait_physics_frames(1)
	assert_true(GameState.game_over.is_connected(go._on_game_over),
		"kontroler nasluchuje GameState.game_over")

func test_controller_smoke_loads() -> void:
	var go = GameOverScene.instantiate()
	add_child_autofree(go)
	await wait_physics_frames(1)
	assert_true(is_instance_valid(go), "game_over.tscn laduje bez crasha")
