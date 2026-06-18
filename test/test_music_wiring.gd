extends GutTest

# P2.7: wpiecie muzyki. play_music/crossfade_to byly martwe - teraz podpiete pod
# sygnaly GameState: gameplay na starcie sesji (session_reset), boss na boss_incoming.
# Pliki audio to placeholdery (brak OGG) - testujemy INTENCJE (current_music_track), nie dzwiek.

func after_each() -> void:
	# Przywroc neutralny stan muzyki, by nie zaburzac innych testow.
	AudioManager.current_music_track = ""

func test_music_catalog_has_gameplay_and_boss() -> void:
	assert_true(AudioManager.MUSIC.has("gameplay"), "katalog muzyki ma gameplay")
	assert_true(AudioManager.MUSIC.has("boss"), "katalog muzyki ma boss")

func test_session_reset_starts_gameplay_music() -> void:
	AudioManager.current_music_track = ""
	GameState.session_reset.emit()
	assert_eq(AudioManager.current_music_track, AudioManager.MUSIC["gameplay"],
		"session_reset startuje muzyke gameplay")

func test_boss_incoming_switches_to_boss_music() -> void:
	AudioManager.current_music_track = ""
	GameState.boss_incoming.emit()
	assert_eq(AudioManager.current_music_track, AudioManager.MUSIC["boss"],
		"boss_incoming przelacza muzyke na boss (crossfade)")

func test_audio_manager_wired_to_session_reset() -> void:
	assert_true(GameState.session_reset.is_connected(AudioManager._on_session_reset),
		"AudioManager nasluchuje session_reset (start muzyki)")

func test_play_music_missing_file_records_intent_no_crash() -> void:
	AudioManager.current_music_track = ""
	AudioManager.play_music(AudioManager.MUSIC["boss"])
	assert_eq(AudioManager.current_music_track, AudioManager.MUSIC["boss"],
		"play_music zapisuje intencje nawet gdy plik to placeholder")

func test_crossfade_to_does_not_crash() -> void:
	AudioManager.crossfade_to(AudioManager.MUSIC["gameplay"], 0.2)
	pass_test("crossfade_to z brakujacym plikiem nie crashuje (graceful)")

func test_crossfade_preserves_user_music_bus_volume() -> void:
	# Regresja: crossfade_to NIE moze nadpisywac glosnosci busa "Music" ustawionej przez
	# gracza (SettingsStore.apply_bus). Crossfade dziala na volume_db odtwarzacza, nie busa.
	var idx := AudioServer.get_bus_index("Music")
	if idx == -1:
		pass_test("brak busa Music w tym srodowisku - pomijam")
		return
	var original := AudioServer.get_bus_volume_db(idx)
	var user_db := -12.0
	AudioServer.set_bus_volume_db(idx, user_db)
	AudioManager.crossfade_to(AudioManager.MUSIC["boss"], 0.1)
	await get_tree().create_timer(0.3).timeout
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), user_db, 0.01,
		"crossfade zachowuje glosnosc busa Music ustawiona przez gracza")
	AudioServer.set_bus_volume_db(idx, original)
