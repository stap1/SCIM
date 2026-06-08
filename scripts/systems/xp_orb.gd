extends Area2D

# Orb XP wypadajacy z wroga. W zasiegu magnesu leci ku graczowi; przy kontakcie
# lub w promieniu pickup_radius zostaje zebrany (raz - guard is_collected).

@export var xp_value: int = 1
@export var pickup_radius: float = 30.0
@export var magnet_speed: float = 250.0
@export var magnet_range: float = 120.0

var is_collected: bool = false
var _player: Node2D = null

func _ready() -> void:
	# Upgrade resource_magnet zwieksza zasieg zbierania nowo powstalych orbow.
	magnet_range *= GameState.magnet_range_mult
	# Orb (mask=1) wykrywa cialo gracza (layer 1) i zbiera sie przy kontakcie.
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	if GameState.is_paused or GameState.is_game_over:
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist < pickup_radius:
		_collect()
		return
	if should_magnetize(dist, magnet_range):
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	GameState.add_xp(xp_value)
	queue_free()

# Czysta funkcja: czy orb powinien leciec ku graczowi.
static func should_magnetize(distance: float, magnet_range_value: float) -> bool:
	return distance < magnet_range_value
