extends Node

# Spawner wrogow. Co spawn_interval tworzy Jellyfish na obrzezu widoku
# i ustawia cel na lodz (grupa "player").

@export var spawn_interval: float = 1.0
@export var max_enemies: int = 30

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const DeathBurstScene := preload("res://scenes/death_burst.tscn")
const XpOrbScene := preload("res://scenes/xp_orb.tscn")

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

func _on_timeout() -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var player := get_tree().get_first_node_in_group("player")
	var vp_size := get_viewport().get_visible_rect().size
	var edge := randi() % 4
	var pos := spawn_position_for_edge(edge, vp_size)

	# Spawn wzgledem widoku gracza (kamera sledzi lodz).
	if player != null:
		pos += player.global_position - vp_size / 2.0

	var enemy := EnemyScene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = pos
	if player != null and enemy.has_method("set_target"):
		enemy.set_target(player)
	# Particle smierci spawnujemy do current_scene (nie do znikajacego wroga).
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(pos: Vector2) -> void:
	var burst := DeathBurstScene.instantiate()
	get_parent().add_child(burst)
	burst.global_position = pos

	var orb := XpOrbScene.instantiate()
	get_parent().add_child(orb)
	orb.global_position = pos

# Czysta funkcja (bez zaleznosci od drzewa): pozycja tuz poza prostokatem widoku.
# edge: 0=gora, 1=prawo, 2=dol, 3=lewo. Zawsze zwraca punkt poza [0, viewport_size].
static func spawn_position_for_edge(edge: int, viewport_size: Vector2) -> Vector2:
	var margin := 50.0
	match edge:
		0:
			return Vector2(randf_range(0.0, viewport_size.x), -margin)
		1:
			return Vector2(viewport_size.x + margin, randf_range(0.0, viewport_size.y))
		2:
			return Vector2(randf_range(0.0, viewport_size.x), viewport_size.y + margin)
		_:
			return Vector2(-margin, randf_range(0.0, viewport_size.y))
