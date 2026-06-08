extends CharacterBody2D

# Mini-boss "Motorowka klusownika". Sledzi gracza i co charge_interval wykonuje szarze
# (Tween ku ostatniej pozycji gracza). HP bar nad bossem. Guard is_dying jak w enemy.gd.

signal boss_defeated(position: Vector2)

@export var max_health: float = 300.0
@export var kill_score: int = 500
@export var track_speed: float = 60.0
@export var charge_interval: float = 3.0
@export var charge_duration: float = 0.45

var health: float
var is_dying: bool = false
var target: Node2D = null

var _charging: bool = false
var _charge_timer: Timer

@onready var hp_bar: ProgressBar = get_node_or_null("HpBar")

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health

	_charge_timer = Timer.new()
	_charge_timer.wait_time = charge_interval
	_charge_timer.autostart = true
	_charge_timer.timeout.connect(_on_charge)
	add_child(_charge_timer)

func set_target(t: Node2D) -> void:
	target = t

func _physics_process(_delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	# W trakcie szarzy pozycja jest sterowana Tweenem - nie nadpisujemy ruchem.
	if _charging:
		return
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if target == null:
		return
	velocity = (target.global_position - global_position).normalized() * track_speed
	move_and_slide()

func _on_charge() -> void:
	if is_dying:
		return
	if target == null or not is_instance_valid(target):
		return
	_charging = true
	var dest := target.global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", dest, charge_duration)
	tween.tween_callback(_end_charge)

func _end_charge() -> void:
	_charging = false

func take_damage(amount: float) -> void:
	if is_dying:
		return
	health -= amount
	if hp_bar:
		hp_bar.value = health
	if health <= 0.0:
		die()

func die() -> void:
	# Death guard (jak w enemy.gd) - przeciw podwojnemu queue_free / podwojnemu score.
	if is_dying:
		return
	is_dying = true
	GameState.enemies_killed += 1
	GameState.add_score(kill_score)
	boss_defeated.emit(global_position)
	queue_free()
