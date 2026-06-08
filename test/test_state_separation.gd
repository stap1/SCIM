extends GutTest

# P1.6: czytelnosc stanu.
# - GameState trzyma WYLACZNIE stan sesji; ustawienia gracza (sesja/accessibility) zyja w SettingsStore.
# - martwy eco_score usuniety.
# - jednostka dlugosci sesji ujednolicona: setting w minutach (czytelny), pure converter na sekundy.

# --- Rozdzielenie: ustawienia opuszczaja GameState ---

func test_eco_score_removed() -> void:
	assert_false("eco_score" in GameState, "martwy eco_score usuniety z GameState")

func test_settings_fields_left_game_state() -> void:
	assert_false("session_length" in GameState, "session_length przeniesione do SettingsStore")
	assert_false("reduce_shake" in GameState, "reduce_shake przeniesione do SettingsStore")
	assert_false("reduce_flashing" in GameState, "reduce_flashing przeniesione do SettingsStore")

func test_settings_live_in_settings_store() -> void:
	assert_true("session_length_min" in SettingsStore, "SettingsStore ma session_length_min")
	assert_true("reduce_shake" in SettingsStore, "SettingsStore ma reduce_shake")
	assert_true("reduce_flashing" in SettingsStore, "SettingsStore ma reduce_flashing")

func test_game_state_keeps_session_fields() -> void:
	# Stan sesji ZOSTAJE w GameState (kontrola, ze nie wycielismy za duzo).
	assert_true("time" in GameState, "time zostaje stanem sesji")
	assert_true("score" in GameState, "score zostaje stanem sesji")
	assert_true("enemies_killed" in GameState, "enemies_killed zostaje stanem sesji")

# --- Ujednolicona jednostka: minuty -> sekundy przez czysta funkcje ---

func test_session_seconds_pure() -> void:
	assert_eq(SettingsStore.session_seconds(15), 900, "15 min = 900 s")
	assert_eq(SettingsStore.session_seconds(10), 600, "10 min = 600 s")
	assert_eq(SettingsStore.session_seconds(0), 0, "0 min = 0 s (brak limitu)")
	assert_eq(SettingsStore.session_seconds(-5), 0, "ujemne -> 0 (bez ujemnego limitu)")

# --- apply_saved zapisuje ustawienia do SettingsStore (nie do GameState) ---

func test_apply_saved_writes_settings_store() -> void:
	var path := SettingsStore.SETTINGS_PATH
	SettingsStore.save_settings(path, 1.0, 1.0, 20, true, true)
	SettingsStore.session_length_min = 0
	SettingsStore.reduce_shake = false
	SettingsStore.reduce_flashing = false
	SettingsStore.apply_saved()
	assert_eq(SettingsStore.session_length_min, 20, "apply_saved ustawia session_length_min z dysku")
	assert_true(SettingsStore.reduce_shake, "apply_saved ustawia reduce_shake")
	assert_true(SettingsStore.reduce_flashing, "apply_saved ustawia reduce_flashing")
	# Sprzatanie: przywroc neutralny config i stan.
	SettingsStore.save_settings(path, 1.0, 1.0, 15, false, false)
	SettingsStore.apply_saved()
