extends GutTest

# KROK 8 (Prompt 8): game over wyzwalany przez GameState.take_damage przy HP<=0,
# emitowany dokladnie raz (guard), reset() czysci stan.

func before_each() -> void:
	GameState.reset()

func test_take_damage_to_zero_emits_game_over_once() -> void:
	watch_signals(GameState)
	GameState.take_damage(200.0) # HP -> 0, game over
	GameState.take_damage(10.0)  # juz po smierci - guard blokuje ponowna emisje
	assert_signal_emit_count(GameState, "game_over", 1,
		"game_over emitowany dokladnie raz mimo dwoch trafien")

func test_reset_clears_game_over_and_restores_health() -> void:
	GameState.take_damage(200.0)
	assert_true(GameState.is_game_over, "po smiertelnym trafieniu is_game_over == true")
	GameState.reset()
	assert_false(GameState.is_game_over, "po reset() is_game_over == false")
	assert_almost_eq(GameState.health, 100.0, 0.001, "po reset() health == 100")
