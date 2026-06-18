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
