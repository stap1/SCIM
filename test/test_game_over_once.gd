extends GutTest

# REGRESJA #3: game_over emitowany dokladnie raz (krok 8).
# Guard one-shot w GameState.trigger_game_over() chroni przed wielokrotna emisja.

func before_each() -> void:
	GameState.is_game_over = false

func after_each() -> void:
	GameState.is_game_over = false

func test_game_over_emitted_exactly_once() -> void:
	watch_signals(GameState)
	GameState.trigger_game_over()
	GameState.trigger_game_over() # drugie wywolanie nie moze emitowac ponownie
	assert_signal_emit_count(GameState, "game_over", 1,
		"game_over musi byc emitowany dokladnie raz (guard one-shot)")

func test_is_game_over_true_after_trigger() -> void:
	GameState.trigger_game_over()
	assert_true(GameState.is_game_over, "Po trigger_game_over() flaga is_game_over musi byc true")
