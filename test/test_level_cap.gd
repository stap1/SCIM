extends GutTest

# #5b: maksymalny poziom = GameConfig.MAX_LEVEL (61, wiek Hemingwaya w chwili smierci).
# add_xp i grant_level_up respektuja cap.

func before_each() -> void:
	GameState.reset()

func test_max_level_constant() -> void:
	assert_eq(GameConfig.MAX_LEVEL, 61, "cap poziomu = 61")

func test_add_xp_caps_level() -> void:
	GameState.level = 60
	watch_signals(GameState)
	GameState.add_xp(100_000_000) # ogromna pula
	assert_eq(GameState.level, 61, "z lvl 60 ogromne XP -> tylko do 61 (cap)")
	assert_signal_emit_count(GameState, "level_up", 1, "tylko jeden awans do cap")

func test_no_level_up_past_cap() -> void:
	GameState.level = 61
	watch_signals(GameState)
	GameState.add_xp(100_000_000)
	assert_eq(GameState.level, 61, "na capie brak dalszych awansow")
	assert_signal_emit_count(GameState, "level_up", 0, "zaden level_up na capie")

func test_xp_zeroed_at_cap() -> void:
	GameState.level = 61
	GameState.xp = 50
	GameState.add_xp(10)
	assert_eq(GameState.xp, 0, "na capie XP wyzerowane (nie ma dokad rosnac)")

func test_grant_level_up_respects_cap() -> void:
	GameState.level = 61
	watch_signals(GameState)
	GameState.grant_level_up()
	assert_eq(GameState.level, 61, "grant_level_up (nagroda bossa) nie przekracza cap")
	assert_signal_emit_count(GameState, "level_up", 0, "brak awansu na capie")

func test_normal_progression_unaffected() -> void:
	# Cap nie rusza niskich poziomow (regresja krzywej XP).
	watch_signals(GameState)
	GameState.add_xp(40) # threshold(1)+threshold(2)=35 -> 2 awanse
	assert_eq(GameState.level, 3, "normalna progresja niezmieniona przez cap")
	assert_signal_emit_count(GameState, "level_up", 2, "dwa awanse jak dotad")
