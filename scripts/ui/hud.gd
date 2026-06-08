extends CanvasLayer

# HUD jest READ-ONLY: czyta GameState wylacznie przez sygnaly.
# NIGDY nie modyfikuje GameState ani nie liczy czasu (czas liczy tylko main.gd przez add_time).

@onready var health_bar: ProgressBar = $HealthBar
@onready var time_label: Label = $TimeLabel
@onready var score_label: Label = $ScoreLabel
@onready var boss_warning: Label = get_node_or_null("BossWarning")
@onready var ammo_label: Label = get_node_or_null("AmmoLabel")

# Pasek HP jako drewniany kadlub: im nizsze HP, tym bardziej "spekany" (etap 0 = caly).
# Docelowo etap -> klatka hull_hp_<stage>.png; do czasu artu placeholder = barwa wypelnienia.
const HULL_STAGES: int = 5
const HULL_HEALTHY := Color(0.55, 0.36, 0.18)  # zdrowe drewno
const HULL_CRITICAL := Color(0.66, 0.13, 0.10)  # roztrzaskany - czerwien alarmu
var _hull_fill: StyleBoxFlat

func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.time_changed.connect(_on_time_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.boss_incoming.connect(_on_boss_incoming)
	if boss_warning:
		boss_warning.hide()

	# Inicjalizacja z aktualnego stanu (niezalezna od kolejnosci _ready scen).
	if health_bar:
		health_bar.max_value = GameState.max_health
		# Wlasna kopia wypelnienia - barwa "kadluba" zmieniana wg etapu zniszczenia.
		var fill := health_bar.get_theme_stylebox("fill")
		if fill:
			_hull_fill = fill.duplicate()
			health_bar.add_theme_stylebox_override("fill", _hull_fill)
	_on_health_changed(GameState.health)
	_on_time_changed(GameState.time)
	_on_score_changed(GameState.score)

	# Licznik amunicji event-driven: sluchaj puli harpunow + synchronizacja poczatkowa
	# (pula moze byc gotowa przed HUD - dlatego dociagamy biezacy stan).
	var pool := get_tree().get_first_node_in_group("harpoon_pool")
	if pool and pool.has_signal("ammo_changed"):
		pool.ammo_changed.connect(_on_ammo_changed)
		_on_ammo_changed(pool.available_count(), pool.total_count())

func _on_ammo_changed(available: int, total: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [available, total]

func _on_health_changed(new_health: float) -> void:
	if health_bar == null:
		return
	health_bar.value = new_health
	# Etap zniszczenia kadluba -> barwa wypelnienia (placeholder do czasu klatek artu).
	if _hull_fill:
		var stage := hull_stage(new_health, health_bar.max_value, HULL_STAGES)
		var t := float(stage) / float(HULL_STAGES - 1)
		_hull_fill.bg_color = HULL_HEALTHY.lerp(HULL_CRITICAL, t)

func _on_time_changed(new_time: float) -> void:
	if time_label:
		time_label.text = format_time(new_time)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Wynik: " + str(new_score)

func _on_boss_incoming() -> void:
	if not boss_warning:
		return
	boss_warning.show()
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(boss_warning):
		boss_warning.hide()

# Czysta funkcja: etap zniszczenia kadluba wg HP (0 = caly, stages-1 = roztrzaskany).
# Etap 0 = 80-100% HP, kolejne co ~20%; uzywane do doboru klatki hull_hp_<stage>.
static func hull_stage(health: float, max_health: float, stages: int) -> int:
	if max_health <= 0.0 or stages <= 1:
		return 0
	var frac := clampf(health / max_health, 0.0, 1.0)
	var stage := int((1.0 - frac) * float(stages))
	return clampi(stage, 0, stages - 1)

# Czysta funkcja: sekundy -> "mm:ss". format_time(75.0) == "01:15".
static func format_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var secs := total % 60
	return "%02d:%02d" % [minutes, secs]
