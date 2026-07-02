extends CanvasLayer

# Ekran konca gry. Reaguje na sygnal GameState.game_over, pauzuje gre, pokazuje
# pelne statystyki (czas, zatopienia, boss, wynik, najlepszy) i pozwala wpisac pseudonim,
# zapisac wynik, zrestartowac lub wrocic do menu. CanvasLayer ma process_mode = ALWAYS.
# Wynik NIGDY nie ginie: wyjscie (restart/menu) bez klikniecia ZAPISZ tez zapisuje
# (puste pole -> HighScores.DEFAULT_NAME).

const HighScores := preload("res://scripts/systems/highscores.gd")

# Warianty nastroju ekranu konca (R4b).
const WIN_COLOR := Color(0.6, 0.95, 0.55, 1)
const LOSS_COLOR := Color(1.0, 0.41, 0.41, 1)
const WIN_BG := Color(0.06, 0.14, 0.10, 0.82)
const LOSS_BG := Color(0.09, 0.09, 0.09, 0.71)

# Sciezka tablicy wynikow - injectowana w testach, by nie dotykac prawdziwego pliku.
var highscores_path: String = HighScores.PATH

@onready var panel: Control = $Panel
@onready var go_label: Label = get_node_or_null("Panel/GameOverLabel")
@onready var background: ColorRect = get_node_or_null("Panel/Background")
@onready var meta_label: Label = get_node_or_null("Panel/MetaLabel")
@onready var final_score_label: Label = get_node_or_null("Panel/FinalScoreLabel")
@onready var time_label: Label = get_node_or_null("Panel/TimeLabel")
@onready var kills_label: Label = get_node_or_null("Panel/KillsLabel")
@onready var boss_label: Label = get_node_or_null("Panel/BossLabel")
@onready var best_label: Label = get_node_or_null("Panel/BestLabel")
@onready var name_label: Label = get_node_or_null("Panel/NameLabel")
@onready var name_edit: LineEdit = get_node_or_null("Panel/NameEdit")
@onready var save_button: Button = get_node_or_null("Panel/SaveScoreButton")
@onready var restart_button: Button = get_node_or_null("Panel/RestartButton")
@onready var menu_button: Button = get_node_or_null("Panel/MenuButton")

# Strzeze przed podwojnym zapisem tego samego wyniku (klik + Enter, podwojny klik, wyjscie).
var _score_saved: bool = false
# Delikatny puls pola pseudonimu - wskazuje miejsce na pisanie, gasnie przy pisaniu/zapisie.
var _blink_tween: Tween

func _ready() -> void:
	if panel:
		panel.hide()
	GameState.game_over.connect(_on_game_over)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if name_label:
		# Limit w prozie z tej samej stalej co twardy limit pola - UI nie klamie po zmianie.
		name_label.text = "Podaj pseudonim (max %d znaków):" % HighScores.NAME_MAX_LEN
	if name_edit:
		name_edit.max_length = HighScores.NAME_MAX_LEN
		name_edit.text_submitted.connect(func(_t: String) -> void: _on_save_pressed())
		name_edit.text_changed.connect(func(t: String) -> void:
			if t != "":
				_stop_name_blink())

func _on_game_over() -> void:
	_score_saved = false
	# Najlepszy wynik liczony PRZED zapisem biezacego (porownanie z dotychczasowym rekordem).
	var top := HighScores.get_top(1, highscores_path)
	var best: int = int(top[0]["score"]) if top.size() > 0 else 0
	var is_record := is_new_record(GameState.score, best)

	if time_label:
		time_label.text = "Czas: " + TimeFormat.mmss(GameState.time)
	if kills_label:
		var j: int = int(GameState.kills_by_type.get(Enemy.EnemyType.JELLYFISH, 0))
		var b: int = int(GameState.kills_by_type.get(Enemy.EnemyType.BARRACUDA, 0))
		var s: int = int(GameState.kills_by_type.get(Enemy.EnemyType.SHARK, 0))
		kills_label.text = kills_breakdown_text(GameState.enemies_killed, j, b, s)
	if boss_label:
		boss_label.text = "Kłusownik pokonany: " + ("TAK" if GameState.miniboss_defeated else "nie")
	if best_label:
		# Pokazujemy najlepszy wynik Z biezacym wlacznie (auto-zapis i tak go utrwali) -
		# label nie moze pokazywac pobitego rekordu obok dopisku NOWY REKORD.
		best_label.text = best_text(maxi(best, GameState.score), is_record)

	# Wariant wygrana/porazka (R4b): tytul, kolory, nastroj.
	if go_label:
		go_label.text = outcome_title(GameState.won)
		go_label.add_theme_color_override("font_color", WIN_COLOR if GameState.won else LOSS_COLOR)
	if background:
		background.color = WIN_BG if GameState.won else LOSS_BG

	# Przeliczenie wyniku na punkty meta i dopisanie na konto (R3b).
	var pts := MetaProgress.score_to_points(GameState.score)
	MetaProgress.add_points(pts)
	if meta_label:
		meta_label.text = "Zdobyte punkty: %d" % pts

	# Pole na pseudonim aktywne ponownie przy kazdym koncu gry.
	if name_edit:
		name_edit.editable = true
	if save_button:
		save_button.disabled = false
		save_button.text = "ZAPISZ WYNIK"

	if panel:
		panel.show()
	get_tree().paused = true
	_count_up_score()
	# Nawigacja klawiatura: najpierw pole pseudonimu (gracz moze od razu pisac, Enter = zapis).
	if name_edit:
		name_edit.grab_focus()
		_start_name_blink()
	elif restart_button:
		restart_button.grab_focus()

# Klik ZAPISZ WYNIK / Enter w polu: zapis + feedback + focus na restart.
func _on_save_pressed() -> void:
	if _score_saved:
		return
	AudioManager.play_sfx("ui_click")
	_save_score_if_needed()
	if restart_button:
		restart_button.grab_focus()

# Zapisuje wynik dokladnie raz na koniec gry (guard _score_saved). Puste pole pseudonimu
# sanityzuje sie do DEFAULT_NAME ('Anon'). Wolane z przycisku/Entera ORAZ przy wyjsciu.
func _save_score_if_needed() -> void:
	if _score_saved:
		return
	_score_saved = true
	_stop_name_blink()
	var player_name: String = name_edit.text if name_edit else ""
	HighScores.add_score(player_name, GameState.score, highscores_path)
	if name_edit:
		name_edit.editable = false
	if save_button:
		save_button.disabled = true
		save_button.text = "ZAPISANO"

# --- Puls pola pseudonimu (delikatne mruganie) ---

func _start_name_blink() -> void:
	if name_edit == null:
		return
	_stop_name_blink()
	# Dostepnosc: przy ograniczeniu migania zostaje statyczne podswietlenie focusa.
	if SettingsStore.reduce_flashing:
		return
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(name_edit, "modulate:a", 0.65, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink_tween.tween_property(name_edit, "modulate:a", 1.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_name_blink() -> void:
	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()
	_blink_tween = null
	if name_edit:
		name_edit.modulate = Color(1, 1, 1, 1)

func _count_up_score() -> void:
	if final_score_label == null:
		return
	var tween := create_tween()
	tween.tween_method(_set_score_text, 0.0, float(GameState.score), 0.8)

func _set_score_text(v: float) -> void:
	if final_score_label:
		final_score_label.text = "Wynik: " + str(int(v))

# Czysta funkcja: tekst statystyki zatopien - suma + rozbicie per typ (B5).
# Suma (enemies_killed) zostaje wiodaca (zgodnosc highscores); rozbicie z kills_by_type.
static func kills_breakdown_text(total: int, jelly: int, barracuda: int, shark: int) -> String:
	return "Zatopione: %d (meduzy %d / barakudy %d / rekiny %d)" % [total, jelly, barracuda, shark]

# Czysta funkcja: tytul ekranu konca wg wyniku (R4b).
static func outcome_title(won: bool) -> String:
	return "WYGRANA" if won else "KONIEC REJSU"

static func is_new_record(score: int, best: int) -> bool:
	return score > 0 and score >= best

static func best_text(best: int, is_record: bool) -> String:
	return "Najlepszy wynik: " + str(best) + ("  (NOWY REKORD!)" if is_record else "")

func _on_restart_pressed() -> void:
	_save_score_if_needed() # wynik nie ginie - zapis PRZED resetem sesji (reset zeruje score)
	AudioManager.play_sfx("ui_click") # ODPALA DŹWIĘK KLIKNIĘCIA
	get_tree().paused = false
	GameState.reset()
	AudioManager.play_music(AudioManager.MUSIC["gameplay"]) # ZMIANA MUZYKI NA GRĘ
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	_save_score_if_needed() # wynik nie ginie - zapis PRZED resetem sesji (reset zeruje score)
	AudioManager.play_sfx("ui_click") # ODPALA DŹWIĘK KLIKNIĘCIA
	get_tree().paused = false
	GameState.reset()
	AudioManager.play_music(AudioManager.MUSIC["menu"]) # ZMIANA MUZYKI NA MENU
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
