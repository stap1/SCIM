extends Control

# Menu glowne. Start uruchamia gre (po GameState.reset()), Ustawienia/Wyniki otwieraja
# odpowiednie sceny, Wyjscie zamyka. Animowane tlo - lodz kolysze sie na falach (Tween).

func _ready() -> void:
	_connect_button("Menu/StartButton", _on_start)
	_connect_button("Menu/ScoresButton", _on_scores)
	_connect_button("Menu/SettingsButton", _on_settings)
	_connect_button("Menu/QuitButton", _on_quit)
	_animate_waves()

func _connect_button(path: String, handler: Callable) -> void:
	var b := get_node_or_null(path)
	if b:
		b.pressed.connect(handler)

func _animate_waves() -> void:
	var boat := get_node_or_null("BoatSprite")
	if boat == null:
		return
	var base_y: float = boat.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(boat, "position:y", base_y - 12.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(boat, "position:y", base_y + 12.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_start() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(ScenePaths.MAIN)

func _on_scores() -> void:
	# Ekran wynikow - krok 21. Otwiera Scores.tscn, jesli juz istnieje.
	if ResourceLoader.exists(ScenePaths.SCORES):
		get_tree().change_scene_to_file(ScenePaths.SCORES)

func _on_settings() -> void:
	get_tree().change_scene_to_file(ScenePaths.SETTINGS)

func _on_quit() -> void:
	get_tree().quit()
