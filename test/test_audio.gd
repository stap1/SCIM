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

func test_fade_volume_db_linear() -> void:
	assert_almost_eq(AudioManager.fade_volume_db(0.0, -10.0, 0.0), -10.0, 0.001, "t=0 -> from")
	assert_almost_eq(AudioManager.fade_volume_db(1.0, -10.0, 0.0), 0.0, 0.001, "t=1 -> to")
	assert_almost_eq(AudioManager.fade_volume_db(0.5, -10.0, 0.0), -5.0, 0.001, "t=0.5 -> srodek")
