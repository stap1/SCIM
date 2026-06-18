extends CanvasLayer

# HUD jest READ-ONLY: czyta GameState wylacznie przez sygnaly.
# NIGDY nie modyfikuje GameState ani nie liczy czasu (czas liczy tylko main.gd przez add_time).

@onready var health_bar: ProgressBar = $HealthBar
@onready var time_label: Label = $TimeLabel
@onready var score_label: Label = $ScoreLabel
@onready var boss_warning: Label = get_node_or_null("BossWarning")
@onready var ammo_label: Label = get_node_or_null("AmmoLabel")
@onready var xp_bar: ProgressBar = get_node_or_null("XPBar")
@onready var level_label: Label = get_node_or_null("LevelLabel")

# Pasek HP jako drewniany kadlub: im nizsze HP, tym bardziej "spekany" (etap 0 = caly).
# Docelowo etap -> klatka hull_hp_<stage>.png; do czasu artu placeholder = barwa wypelnienia.
const HULL_STAGES: int = 5
const HULL_HEALTHY := Color(0.55, 0.36, 0.18)  # zdrowe drewno (placeholder barwy)
const HULL_CRITICAL := Color(0.66, 0.13, 0.10)  # roztrzaskany - czerwien alarmu
const HULL_TEX_PATHS: Array[String] = [
	"res://assets/hull_hp_0.png", "res://assets/hull_hp_1.png", "res://assets/hull_hp_2.png",
	"res://assets/hull_hp_3.png", "res://assets/hull_hp_4.png",
]
var _hull_fill: StyleBoxFlat
var _hull_sprite: TextureRect
var _hull_textures: Array = []

func _ready() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.time_changed.connect(_on_time_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.boss_incoming.connect(_on_boss_incoming)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.level_up.connect(_on_level_up)
	if boss_warning:
		boss_warning.hide()

	# Pasek HP jako kadlub: preload 5 klatek (graceful null gdy brak pliku - wtedy zostaje
	# ProgressBar z barwa jako fallback).
	_hull_sprite = get_node_or_null("HullSprite")
	for p in HULL_TEX_PATHS:
		_hull_textures.append(load(p) if ResourceLoader.exists(p) else null)

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
	_refresh_xp()
	_set_level(GameState.level)

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
	# Etap zniszczenia kadluba (0 = caly, 4 = roztrzaskany).
	var stage := hull_stage(new_health, health_bar.max_value, HULL_STAGES)
	# Klatka kadluba wg etapu (gdy art dostepny); inaczej barwa wypelnienia jako fallback.
	if _hull_sprite and stage < _hull_textures.size() and _hull_textures[stage] != null:
		_hull_sprite.texture = _hull_textures[stage]
	if _hull_fill:
		var t := float(stage) / float(HULL_STAGES - 1)
		_hull_fill.bg_color = HULL_HEALTHY.lerp(HULL_CRITICAL, t)

func _on_time_changed(new_time: float) -> void:
	if time_label:
		time_label.text = format_time(new_time)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Wynik: " + str(new_score)

func _on_xp_changed(_new_xp: int) -> void:
	_refresh_xp()

func _on_level_up(new_level: int) -> void:
	_set_level(new_level)
	_refresh_xp() # awans zmienia prog i zeruje xp - odswiez pasek

# Pasek XP czyta GameState (read-only): wartosc = xp, skala = prog biezacego poziomu.
func _refresh_xp() -> void:
	if xp_bar == null:
		return
	var v := xp_bar_values(GameState.xp, GameState.xp_to_next)
	xp_bar.max_value = v.y
	xp_bar.value = v.x

func _set_level(lvl: int) -> void:
	if level_label:
		level_label.text = level_text(lvl)

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

# Sekundy -> "mm:ss". Deleguje do wspolnego TimeFormat (jedno zrodlo formatu).
static func format_time(seconds: float) -> String:
	return TimeFormat.mmss(seconds)

# Czysta funkcja: (value, max) paska XP. Na maksie (xp_to_next<=0) pasek pelny, bez
# dzielenia przez zero. Zwraca Vector2i(value, max_value).
static func xp_bar_values(xp: int, xp_to_next: int) -> Vector2i:
	if xp_to_next > 0:
		return Vector2i(xp, xp_to_next)
	return Vector2i(1, 1)

# Czysta funkcja: etykieta poziomu. level_text(3) == "Poziom: 3".
static func level_text(level: int) -> String:
	return "Poziom: %d" % level
