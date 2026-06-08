extends GutTest

# KROK 13 (Prompt 13): krzywa XP, level_up, wiele awansow naraz.

func before_each() -> void:
	GameState.reset()

func test_xp_threshold_formula() -> void:
	assert_eq(GameState.xp_threshold(1), 10, "xp_threshold(1) == 10")
	assert_eq(GameState.xp_threshold(2), 25, "xp_threshold(2) == 25")
	assert_eq(GameState.xp_threshold(3), 50, "xp_threshold(3) == 50")

func test_single_level_up() -> void:
	watch_signals(GameState)
	GameState.add_xp(20) # > xp_threshold(1) = 10
	assert_eq(GameState.level, 2, "przekroczenie progu poziomu 1 -> level 2")
	assert_signal_emit_count(GameState, "level_up", 1, "level_up wyemitowany raz")

func test_multiple_level_ups() -> void:
	watch_signals(GameState)
	# threshold(1)+threshold(2) = 10+25 = 35, ponizej +threshold(3) -> dokladnie 2 awanse.
	GameState.add_xp(40)
	assert_eq(GameState.level, 3, "duza wartosc -> dwa awanse -> level 3")
	assert_signal_emit_count(GameState, "level_up", 2, "level_up wyemitowany dwa razy")
