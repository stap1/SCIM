extends CanvasLayer

# Ekran konca gry. Reaguje na sygnal GameState.game_over, pauzuje gre, pokazuje
# pelne statystyki (czas, zatopienia, boss, wynik, najlepszy) i pozwala zrestartowac
# lub wrocic do menu. CanvasLayer ma process_mode = ALWAYS (przyciski dzialaja przy pauzie).

const HighScores := preload("res://scripts/systems/highscores.gd")

@onready var panel: Control = $Panel
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
	# Zapis wyniku do tablicy rekordow, potem odczyt najlepszego.
	HighScores.add_score(GameState.score)
	var top := HighScores.get_top(1)
	var best: int = top[0] if top.size() > 0 else 0
	var is_record := is_new_record(GameState.score, best)

	if time_label:
		time_label.text = "Czas: " + _format_time(GameState.time)
	if kills_label:
		kills_label.text = "Zatopione: " + str(GameState.enemies_killed)
	if boss_label:
		boss_label.text = "Klusownik pokonany: " + ("TAK" if GameState.miniboss_defeated else "nie")
	if best_label:
		best_label.text = best_text(best, is_record)

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

func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]

# Czysta funkcja: czy biezacy wynik to nowy rekord (>= najlepszego, pomijajac pusty przebieg 0).
static func is_new_record(score: int, best: int) -> bool:
	return score > 0 and score >= best

# Czysta funkcja: etykieta najlepszego wyniku z oznaczeniem rekordu.
static func best_text(best: int, is_record: bool) -> String:
	return "Najlepszy wynik: " + str(best) + ("  (NOWY REKORD!)" if is_record else "")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
