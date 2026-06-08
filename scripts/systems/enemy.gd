extends CharacterBody2D

signal died(position: Vector2)

@export var speed: float = 80.0
@export var max_health: float = 10.0
@export var kill_score: int = 1

var health: float
var is_dying: bool = false
var target: Node2D = null

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	if has_node("SpawnSound"):
		$SpawnSound.play()

func set_target(t: Node2D) -> void:
	target = t

func _physics_process(_delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return

	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if target == null:
		return

	velocity = (target.global_position - global_position).normalized() * speed
	move_and_slide()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		die()

func die() -> void:
	# Death guard: pierwsza smierc wygrywa, kolejne wywolania ignorowane (brak podwojnego score/queue_free).
	if is_dying:
		return
	is_dying = true

	GameState.add_score(kill_score)
	# Sygnal niesie pozycje ZANIM wezel zniknie - DeathBurst spawnuje sie niezaleznie w current_scene.
	died.emit(global_position)
	queue_free()
