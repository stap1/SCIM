extends GutTest

# R4a: wynik sesji boss-aware (koniec czasu nie przerywa walki z bossem) + blokada wygranej.

const Main := preload("res://scripts/systems/main.gd")

func after_each() -> void:
	GameState.reset()

func test_continue_before_limit() -> void:
	assert_eq(Main.session_outcome(100.0, 300, false, false), Main.Outcome.CONTINUE, "przed limitem -> graj")

func test_continue_when_boss_alive_past_limit() -> void:
	assert_eq(Main.session_outcome(305.0, 300, true, false), Main.Outcome.CONTINUE,
		"czas minal ale boss zyje -> graj dalej")

func test_win_when_time_up_and_no_boss() -> void:
	assert_eq(Main.session_outcome(300.0, 300, false, false), Main.Outcome.WIN, "czas minal, brak bossa -> wygrana")

func test_loss_when_player_dead() -> void:
	assert_eq(Main.session_outcome(50.0, 300, true, true), Main.Outcome.LOSS, "smierc -> porazka niezaleznie")

func test_no_limit_never_wins_by_time() -> void:
	assert_eq(Main.session_outcome(99999.0, 0, false, false), Main.Outcome.CONTINUE, "brak limitu -> brak wygranej z czasu")

# --- GameState: wygrana / blokada porazki ---

func test_trigger_victory_sets_won() -> void:
	GameState.reset()
	GameState.trigger_game_over(true)
	assert_true(GameState.is_game_over, "gra zakonczona")
	assert_true(GameState.won, "wygrana ustawia won")

func test_trigger_default_is_loss() -> void:
	GameState.reset()
	GameState.trigger_game_over()
	assert_false(GameState.won, "domyslnie porazka (won=false)")

func test_victory_locked_blocks_loss() -> void:
	GameState.reset()
	GameState.victory_locked = true
	watch_signals(GameState)
	GameState.take_damage(99999.0)
	assert_signal_not_emitted(GameState, "game_over", "smierc podczas laski nie konczy porazka")
