extends GutTest

# KROK 19 (Prompt 19): AudioManager - SFX z graceful fallback, czysta fade_volume_db.

func test_singleton_has_methods() -> void:
	assert_true(AudioManager.has_method("play_sfx"), "AudioManager ma play_sfx")
	assert_true(AudioManager.has_method("play_music"), "AudioManager ma play_music")
	assert_true(AudioManager.has_method("crossfade_to"), "AudioManager ma crossfade_to")

func test_play_sfx_unknown_does_not_crash() -> void:
	AudioManager.play_sfx("nieistniejacy_klucz")
	pass_test("play_sfx z nieznanym kluczem nie crashuje (graceful fallback)")

func test_play_sfx_missing_file_does_not_crash() -> void:
	# Klucz istnieje, ale plik to placeholder (pusta sciezka) - cichy fallback bez crasha.
	AudioManager.play_sfx("level_up")
	pass_test("play_sfx z brakujacym plikiem nie crashuje")

func test_sfx_pool_size() -> void:
	# P3.3: wieksza pula SFX zapobiega ucinaniu przy wielu zdarzeniach naraz.
	assert_eq(AudioManager.SFX_POOL_SIZE, 16, "SFX_POOL_SIZE 16")
	assert_eq(AudioManager._sfx_players.size(), 16, "utworzono 16 odtwarzaczy SFX")

func test_fade_volume_db_linear() -> void:
	assert_almost_eq(AudioManager.fade_volume_db(0.0, -10.0, 0.0), -10.0, 0.001, "t=0 -> from")
	assert_almost_eq(AudioManager.fade_volume_db(1.0, -10.0, 0.0), 0.0, 0.001, "t=1 -> to")
	assert_almost_eq(AudioManager.fade_volume_db(0.5, -10.0, 0.0), -5.0, 0.001, "t=0.5 -> srodek")

# --- Combo XP: czysta funkcja compute_xp_playback (dodana 24.06.2026) ---

func test_xp_first_pickup_plays_at_base_pitch() -> void:
	# Pierwszy zbior po dlugiej ciszy: ton bazowy 1.0, gramy, czas = teraz.
	var s := AudioManager.compute_xp_playback(5000, 0, 1.0)
	assert_true(s["play"], "po ciszy gramy")
	assert_almost_eq(s["pitch"], 1.0, 0.001, "ton bazowy 1.0")
	assert_eq(s["next_last_ms"], 5000, "znacznik czasu = teraz")

func test_xp_idle_resets_combo_pitch() -> void:
	# Przerwa > XP_COMBO_RESET_MS resetuje narosly ton do 1.0.
	var s := AudioManager.compute_xp_playback(2000, 500, 1.4)
	assert_almost_eq(s["pitch"], 1.0, 0.001, "combo wygaslo -> reset do 1.0")
	assert_true(s["play"], "po resecie i tak gramy")

func test_xp_throttle_skips_play_but_bumps_pitch() -> void:
	# Zbior gestszy niz XP_THROTTLE_MS: nie gramy, ton rosnie o krok throttle,
	# a znacznik czasu zostaje bez zmian (porownujemy do ostatniego ZAGRANEGO).
	var s := AudioManager.compute_xp_playback(120, 100, 1.2)
	assert_false(s["play"], "za gesto -> nie gramy")
	assert_almost_eq(s["next_pitch"], 1.22, 0.001, "ton +0.02 (krok throttle)")
	assert_eq(s["next_last_ms"], 100, "czas ostatniego zagrania bez zmian")

func test_xp_normal_play_advances_pitch() -> void:
	# Zbior poza oknem throttle: gramy i ton rosnie o krok grania.
	var s := AudioManager.compute_xp_playback(300, 100, 1.2)
	assert_true(s["play"], "poza throttle -> gramy")
	assert_almost_eq(s["next_pitch"], 1.25, 0.001, "ton +0.05 (krok grania)")
	assert_eq(s["next_last_ms"], 300, "czas = teraz")

func test_xp_pitch_caps_at_max() -> void:
	# Ton nie przekracza XP_PITCH_MAX nawet przy ciaglym narastaniu.
	var s := AudioManager.compute_xp_playback(300, 100, 1.49)
	assert_almost_eq(s["next_pitch"], AudioManager.XP_PITCH_MAX, 0.001, "ton uciety do 1.5")

func test_xp_volume_compensation_endpoints() -> void:
	# Kompensacja glosnosci: ton bazowy -> 0 dB, ton maksymalny -> XP_VOLUME_MIN_DB.
	var base := AudioManager.compute_xp_playback(300, 100, 1.0)
	assert_almost_eq(base["volume_db"], 0.0, 0.001, "ton 1.0 -> 0 dB")
	var loud := AudioManager.compute_xp_playback(300, 100, AudioManager.XP_PITCH_MAX)
	assert_almost_eq(loud["volume_db"], AudioManager.XP_VOLUME_MIN_DB, 0.001, "ton 1.5 -> -6 dB")

func test_bus_or_master_falls_back_to_master() -> void:
	# Routing: nieistniejacy bus -> bezpieczny fallback do Master (zob. _bus_or_master).
	assert_eq(AudioManager._bus_or_master("Nieistniejacy_Bus_123"), "Master",
		"brak busa -> Master")

func test_play_sfx_xp_pickup_burst_does_not_crash() -> void:
	# Regresja integracyjna: seria zbiorow XP (combo + throttle) nie wywala gry.
	for i in 30:
		AudioManager.play_sfx("xp_pickup")
	pass_test("seria xp_pickup nie crashuje")

func test_all_declared_audio_paths_exist() -> void:
	# Regresja: kazda NIEPUSTA sciezka SFX i kazdy utwor MUSIC musi wskazywac istniejacy
	# zasob (pusty string = swiadomy placeholder). Lapie wiszace sciezki - jak
	# boss_spawn.ogg/game_over.ogg po refaktorze audio (eaf3c90).
	for key in AudioManager.SFX_PATHS:
		var path: String = AudioManager.SFX_PATHS[key]
		if path != "":
			assert_true(ResourceLoader.exists(path), "SFX '%s' -> istniejacy plik (%s)" % [key, path])
	for key in AudioManager.MUSIC:
		var path: String = AudioManager.MUSIC[key]
		assert_true(ResourceLoader.exists(path), "MUSIC '%s' -> istniejacy plik (%s)" % [key, path])
