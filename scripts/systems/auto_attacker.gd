extends Node

# Auto-celowanie: co attack_interval znajduje najblizszego wroga w zasiegu,
# pobiera harpun z HarpoonPool i strzela z pozycji lodzi w jego kierunku.

@export var attack_interval: float = 0.8
@export var attack_range: float = 350.0

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = attack_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

func _on_timeout() -> void:
	if GameState.is_game_over:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Zbieramy pozycje zywych wrogow (is_instance_valid - mogli zginac w tej klatce).
	var valid: Array = []
	var positions: Array[Vector2] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			valid.append(e)
			positions.append(e.global_position)

	var idx := find_nearest(player.global_position, positions, attack_range)
	if idx == -1:
		return

	var target = valid[idx]
	var pool := get_tree().get_first_node_in_group("harpoon_pool")
	if pool == null:
		return

	var harpoon = pool.get_harpoon()
	if harpoon:
		var dir: Vector2 = (target.global_position - player.global_position).normalized()
		harpoon.fire(player.global_position, dir)
		if player.has_method("play_shoot_sound"):
			player.play_shoot_sound()

# Czysta funkcja bez zaleznosci od drzewa: indeks najblizszej pozycji w zasiegu (lub -1).
static func find_nearest(origin: Vector2, positions: Array[Vector2], max_range: float) -> int:
	var best := -1
	var best_dist := INF
	for i in positions.size():
		var d := origin.distance_to(positions[i])
		if d <= max_range and d < best_dist:
			best = i
			best_dist = d
	return best
