extends CanvasLayer

# HUD jest READ-ONLY: czyta GameState wylacznie przez sygnaly.
# NIGDY nie modyfikuje GameState ani nie liczy czasu (czas liczy tylko main.gd przez add_time).

@onready var health_bar: ProgressBar = $HealthBar
@onready var time_label: Label = $TimeLabel
@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.time_changed.connect(_on_time_changed)
	GameState.score_changed.connect(_on_score_changed)

	# Inicjalizacja z aktualnego stanu (niezalezna od kolejnosci _ready scen).
	if health_bar:
		health_bar.max_value = GameState.max_health
	_on_health_changed(GameState.health)
	_on_time_changed(GameState.time)
	_on_score_changed(GameState.score)

func _on_health_changed(new_health: float) -> void:
	if health_bar:
		health_bar.value = new_health

func _on_time_changed(new_time: float) -> void:
	if time_label:
		time_label.text = format_time(new_time)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Wynik: " + str(new_score)

# Czysta funkcja: sekundy -> "mm:ss". format_time(75.0) == "01:15".
static func format_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var secs := total % 60
	return "%02d:%02d" % [minutes, secs]
