extends GutTest

# KROK 14 (Prompt 14): levelup screen - 3 karty, pauza, pick_three.

const LevelUpScene := preload("res://scenes/ui/level_up.tscn")
const LevelUpScript := preload("res://scripts/ui/level_up.gd")

func after_each() -> void:
	# Bezpiecznik: gdyby test zostawil zapauzowane drzewo.
	get_tree().paused = false

func test_pick_three_returns_three_unique() -> void:
	var pool: Array[String] = ["a", "b", "c", "d", "e", "f"]
	var r := LevelUpScript.pick_three(pool, 123)
	assert_eq(r.size(), 3, "pick_three zwraca 3 opcje")
	assert_true(r[0] != r[1] and r[1] != r[2] and r[0] != r[2], "3 unikalne opcje")

func test_pick_three_deterministic() -> void:
	var pool: Array[String] = ["a", "b", "c", "d", "e", "f"]
	assert_eq(LevelUpScript.pick_three(pool, 42), LevelUpScript.pick_three(pool, 42),
		"ten sam seed -> ten sam wynik")

func test_level_up_shows_and_pauses_then_resumes() -> void:
	var lu = LevelUpScene.instantiate()
	add_child_autofree(lu)
	await wait_physics_frames(1)

	# Emisja level_up - bez await dopoki zapauzowane (inaczej zawiesiloby GUT).
	GameState.level_up.emit(2)
	assert_true(lu.get_node("Panel").visible, "ekran widoczny po level_up")
	assert_true(get_tree().paused, "gra zapauzowana po level_up")

	watch_signals(lu)
	lu._on_card_pressed(0)
	assert_false(get_tree().paused, "po wyborze karty gra wznowiona")
	assert_signal_emitted(lu, "upgrade_chosen", "klik karty emituje upgrade_chosen")
