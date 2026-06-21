extends Control

# Menu glowne. Start uruchamia gre (po GameState.reset()), Ustawienia/Wyniki otwieraja
# odpowiednie sceny, Wyjscie zamyka. Animowane tlo - lodz kolysze sie na falach (Tween).

# Sciezka przycisku, na ktory ma wrocic focus po powrocie z podmenu (statyczne - przetrwa
# zmiane sceny). Ustawiane przy wejsciu w podmenu, czytane w _ready po powrocie.
static var _return_focus: String = ""

func _ready() -> void:
	# Gwarancja muzyki menu (np. powrot z pauzy resetuje sesje -> gralaby muzyka gry).
	if AudioManager.current_music_track != AudioManager.MUSIC["menu"]:
		AudioManager.play_music(AudioManager.MUSIC["menu"])

	# SZYBKA GRA (5 min) = jedyny aktywny start; NOWA GRA wyszarzona (przyszlosc).
	_connect_button("Menu/QuickGameButton", _on_quick_game)
	_connect_button("Menu/UpgradesButton", _on_upgrades)
	_connect_button("Menu/SettingsButton", _on_settings)
	_connect_button("Menu/ScoresButton", _on_scores)
	_connect_button("Menu/CreditsButton", _on_credits)
	_connect_button("Menu/QuitButton", _on_quit)
	_animate_waves()

	# Nawigacja klawiatura: focus wraca na opcje, z ktorej wrocilismy (lub SZYBKA GRA).
	var focus_path := _return_focus
	_return_focus = ""
	var btn: Button = get_node_or_null(focus_path) as Button if focus_path != "" else null
	if btn == null or btn.disabled:
		btn = get_node_or_null("Menu/QuickGameButton") as Button
	if btn:
		btn.grab_focus()

func _connect_button(path: String, handler: Callable) -> void:
	var b := get_node_or_null(path)
	if b:
		b.pressed.connect(handler)
		# Ta jedna linijka sprawia, ze kazdy zdefiniowany wyzej przycisk wywola Twoj sfx!
		b.pressed.connect(func(): AudioManager.play_sfx("ui_click"))

func _animate_waves() -> void:
	var boat := get_node_or_null("BoatSprite")
	if boat == null:
		return
	var base_y: float = boat.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(boat, "position:y", base_y - 12.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(boat, "position:y", base_y + 12.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_quick_game() -> void:
	SettingsStore.session_length_min = 5  # tryb szybkiej gry: stale 5 minut
	GameState.reset()
	get_tree().change_scene_to_file(ScenePaths.MAIN)

# Otwiera popup ULEPSZENIA (sklep meta-progresji). Popup zyje w scenie menu (R3c).
func _on_upgrades() -> void:
	var popup := get_node_or_null("UpgradesMenu")
	if popup != null and popup.has_method("open"):
		# Przekaz przycisk ULEPSZENIA - po zamknieciu popupa focus tam wroci (nawigacja klawiatura).
		popup.open(get_node_or_null("Menu/UpgradesButton"))

func _on_credits() -> void:
	_return_focus = "Menu/CreditsButton"
	get_tree().change_scene_to_file(ScenePaths.CREDITS)

func _on_scores() -> void:
	# Ekran wynikow - krok 21. Otwiera Scores.tscn, jesli juz istnieje.
	if ResourceLoader.exists(ScenePaths.SCORES):
		_return_focus = "Menu/ScoresButton"
		get_tree().change_scene_to_file(ScenePaths.SCORES)

func _on_settings() -> void:
	_return_focus = "Menu/SettingsButton"
	get_tree().change_scene_to_file(ScenePaths.SETTINGS)

func _on_quit() -> void:
	get_tree().quit()
