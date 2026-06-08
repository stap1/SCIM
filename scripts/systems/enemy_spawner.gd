extends Node

# Spawner wrogow. Trudnosc rosnie z czasem wg difficulty_curve (DANE, nie kod):
# klucz = minuta, wartosc = {enemies: [typy], spawn_interval}. Co tick spawner odczytuje
# aktualny tier (current_tier), dostosowuje interval Timera i losuje typ z dozwolonej listy.
# Wszystkie typy uzywaja enemy.gd (jedna baza).

@export var max_enemies: int = 30

const JellyfishScene := preload("res://scenes/enemies/enemy.tscn")
const BarracudaScene := preload("res://scenes/enemies/barracuda.tscn")
const SharkScene := preload("res://scenes/enemies/shark.tscn")
const DeathBurstScene := preload("res://scenes/death_burst.tscn")
const XpOrbScene := preload("res://scenes/xp_orb.tscn")

# Balans edytowalny w jednym miejscu - bez dotykania logiki.
var difficulty_curve := {
	0: {"enemies": [JellyfishScene], "spawn_interval": 1.2},
	1: {"enemies": [JellyfishScene, BarracudaScene], "spawn_interval": 1.0},
	2: {"enemies": [JellyfishScene, BarracudaScene, SharkScene], "spawn_interval": 0.8},
	3: {"enemies": [JellyfishScene, BarracudaScene, SharkScene], "spawn_interval": 0.6},
}

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = difficulty_curve[0]["spawn_interval"]
	_timer.autostart = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

func _on_timeout() -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return

	var tier := current_tier(GameState.time, _curve_keys())
	var entry: Dictionary = difficulty_curve[tier]
	_timer.wait_time = entry["spawn_interval"]

	var allowed: Array = entry["enemies"]
	if allowed.is_empty():
		return
	spawn_enemy(allowed[randi() % allowed.size()])

func _curve_keys() -> Array[int]:
	var keys: Array[int] = []
	for k in difficulty_curve:
		keys.append(k)
	return keys

func spawn_enemy(scene: PackedScene) -> Node:
	var player := get_tree().get_first_node_in_group("player")
	var vp_size := get_viewport().get_visible_rect().size
	var pos := spawn_position_for_edge(randi() % 4, vp_size)

	# Spawn wzgledem widoku gracza (kamera sledzi lodz).
	if player != null:
		pos += player.global_position - vp_size / 2.0

	var enemy := scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = pos
	if player != null and enemy.has_method("set_target"):
		enemy.set_target(player)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	return enemy

func _on_enemy_died(pos: Vector2) -> void:
	var burst := DeathBurstScene.instantiate()
	get_parent().add_child(burst)
	burst.global_position = pos

	var orb := XpOrbScene.instantiate()
	get_parent().add_child(orb)
	orb.global_position = pos

# Czysta funkcja: najwyzszy klucz krzywej <= aktualnej minucie (floor(time/60)).
static func current_tier(time_seconds: float, curve_keys: Array[int]) -> int:
	var minute := int(floor(time_seconds / 60.0))
	var best := -1
	for k in curve_keys:
		if k <= minute and k > best:
			best = k
	if best == -1 and not curve_keys.is_empty():
		best = curve_keys.min()
	return best

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
