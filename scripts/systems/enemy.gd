extends CharacterBody2D

# Sygnal niesie pozycje (dla efektu) ORAZ xp_value (ile warty jest zrzucony orb).
signal died(position: Vector2, xp_value: int)

# Wartosci bazowe (meduza) z GameConfig; barracuda/rekin nadpisuja w scenach .tscn.
@export var speed: float = GameConfig.ENEMY_JELLYFISH_SPEED
@export var max_health: float = GameConfig.ENEMY_JELLYFISH_HP
@export var kill_score: int = GameConfig.ENEMY_JELLYFISH_SCORE
# Wartosc orba XP zrzucanego po smierci (mocniejsi wrogowie = wiecej).
@export var xp_value: int = GameConfig.XP_ORB_VALUE

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

	GameState.enemies_killed += 1
	GameState.add_score(kill_score)
	# Sygnal niesie pozycje + wartosc orba ZANIM wezel zniknie - spawner reaguje niezaleznie.
	died.emit(global_position, xp_value)
	queue_free()
