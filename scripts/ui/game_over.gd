extends CanvasLayer

# Ekran konca gry. Reaguje na sygnal GameState.game_over, pauzuje gre, pokazuje
# pelne statystyki (czas, zatopienia, boss, wynik, najlepszy) i pozwala zrestartowac
# lub wrocic do menu. CanvasLayer ma process_mode = ALWAYS (przyciski dzialaja przy pauzie).

const HighScores := preload("res://scripts/systems/highscores.gd")

# Warianty nastroju ekranu konca (R4b).
const WIN_COLOR := Color(0.6, 0.95, 0.55, 1)
const LOSS_COLOR := Color(1.0, 0.41, 0.41, 1)
const WIN_BG := Color(0.06, 0.14, 0.10, 0.82)
const LOSS_BG := Color(0.09, 0.09, 0.09, 0.71)

@onready var panel: Control = $Panel
@onready var go_label: Label = get_node_or_null("Panel/GameOverLabel")
@onready var background: ColorRect = get_node_or_null("Panel/Background")
@onready var meta_label: Label = get_node_or_null("Panel/MetaLabel")
@onready var final_score_label: Label = get_node_or_null("Panel/FinalScoreLabel")
@onready var time_label: Label = get_node_or_null("Panel/TimeLabel")
@onready var kills_label: Label = get_node_or_null("Panel/KillsLabel")
@onready var boss_label: Label = get_node_or_null("Panel/BossLabel")
@onready var best_label: Label = get_node_or_null("Panel/BestLabel")
@onready var restart_button: Button = get_node_or_null("Panel/RestartButton")
@onready var menu_button: Button = get_node_or_null("Panel/MenuButton")

func _ready() -> void:
	if panel:
		panel.hide()
	GameState.game_over.connect(_on_game_over)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _on_game_over() -> void:
	HighScores.add_score(GameState.score)
	var top := HighScores.get_top(1)
	var best: int = top[0] if top.size() > 0 else 0
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
		best_label.text = best_text(best, is_record)

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

	if panel:
		panel.show()
	get_tree().paused = true
	_count_up_score()

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
	AudioManager.play_sfx("ui_click") # ODPALA DŹWIĘK KLIKNIĘCIA
	get_tree().paused = false
	GameState.reset()
	AudioManager.play_music(AudioManager.MUSIC["gameplay"]) # ZMIANA MUZYKI NA GRĘ
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click") # ODPALA DŹWIĘK KLIKNIĘCIA
	get_tree().paused = false
	GameState.reset()
	AudioManager.play_music(AudioManager.MUSIC["menu"]) # ZMIANA MUZYKI NA MENU
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
