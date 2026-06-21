extends Control

# Menu glowne. Start uruchamia gre (po GameState.reset()), Ustawienia/Wyniki otwieraja
# odpowiednie sceny, Wyjscie zamyka. Animowane tlo - lodz kolysze sie na falach (Tween).

func _ready() -> void:
	# SZYBKA GRA (5 min) = jedyny aktywny start; NOWA GRA wyszarzona (przyszlosc).
	_connect_button("Menu/QuickGameButton", _on_quick_game)
	_connect_button("Menu/UpgradesButton", _on_upgrades)
	_connect_button("Menu/SettingsButton", _on_settings)
	_connect_button("Menu/ScoresButton", _on_scores)
	_connect_button("Menu/CreditsButton", _on_credits)
	_connect_button("Menu/QuitButton", _on_quit)
	_animate_waves()
	# Nawigacja klawiatura: focus na pierwszej aktywnej pozycji (strzalki/enter/spacja dzialaja).
	var first := get_node_or_null("Menu/QuickGameButton")
	if first:
		first.grab_focus()

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
		popup.open()

func _on_credits() -> void:
	get_tree().change_scene_to_file(ScenePaths.CREDITS)

func _on_scores() -> void:
	# Ekran wynikow - krok 21. Otwiera Scores.tscn, jesli juz istnieje.
	if ResourceLoader.exists(ScenePaths.SCORES):
		get_tree().change_scene_to_file(ScenePaths.SCORES)

func _on_settings() -> void:
	get_tree().change_scene_to_file(ScenePaths.SETTINGS)

func _on_quit() -> void:
	get_tree().quit()
