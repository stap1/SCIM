extends GutTest

# KROK 2 (Prompt 2): testy logiki GameState - jedynego zrodla prawdy o stanie sesji.

func before_each() -> void:
	GameState.reset()

func test_reset_sets_start_values() -> void:
	GameState.score = 99
	GameState.time = 50.0
	GameState.level = 7
	GameState.health = 3.0
	GameState.reset()
	assert_almost_eq(GameState.health, 100.0, 0.001, "reset() -> health 100")
	assert_eq(GameState.score, 0, "reset() -> score 0")
	assert_almost_eq(GameState.time, 0.0, 0.001, "reset() -> time 0")
	assert_eq(GameState.level, 1, "reset() -> level 1")

func test_add_score_accumulates_and_emits() -> void:
	watch_signals(GameState)
	GameState.add_score(5)
	GameState.add_score(3)
	assert_eq(GameState.score, 8, "add_score(5) + add_score(3) -> score 8")
	assert_signal_emitted(GameState, "score_changed", "add_score musi emitowac score_changed")

func test_take_damage_reduces_health() -> void:
	GameState.take_damage(30.0)
	assert_almost_eq(GameState.health, 70.0, 0.001, "take_damage(30) -> health 70")

func test_take_damage_clamps_at_zero() -> void:
	GameState.take_damage(1000.0)
	assert_almost_eq(GameState.health, 0.0, 0.001, "take_damage(1000) -> health 0 (nigdy ujemne)")

func test_take_damage_emits_health_changed() -> void:
	watch_signals(GameState)
	GameState.take_damage(10.0)
	assert_signal_emitted(GameState, "health_changed", "take_damage musi emitowac health_changed")

func test_add_time_accumulates() -> void:
	GameState.add_time(0.5)
	GameState.add_time(0.5)
	assert_almost_eq(GameState.time, 1.0, 0.001, "add_time(0.5) x2 -> time 1.0")

func test_add_time_emits_time_changed() -> void:
	watch_signals(GameState)
	GameState.add_time(0.5)
	assert_signal_emitted(GameState, "time_changed", "add_time musi emitowac time_changed")
