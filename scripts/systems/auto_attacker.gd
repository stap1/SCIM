extends Node

# Auto-celowanie: co attack_interval znajduje najblizszych wrogow w zasiegu,
# pobiera harpuny z HarpoonPool i strzela z pozycji lodzi. Liczba pociskow na atak
# (1 lub 2 po double_harpoon) okresla, ilu najblizszych wrogow zostanie ostrzelanych.

@export var attack_interval: float = 0.8
@export var attack_range: float = 350.0
var projectiles_per_attack: int = 1

var _timer: Timer

func _ready() -> void:
	add_to_group("auto_attacker")
	_timer = Timer.new()
	_timer.wait_time = attack_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

func set_attack_interval(value: float) -> void:
	attack_interval = value
	if _timer:
		_timer.wait_time = value

func _on_timeout() -> void:
	if GameState.is_game_over:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var pool := get_tree().get_first_node_in_group("harpoon_pool")
	if pool == null:
		return

	# Zbieramy zywych wrogow (is_instance_valid - mogli zginac w tej klatce).
	var valid: Array = []
	var remaining: Array[Vector2] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			valid.append(e)
			remaining.append(e.global_position)

	# Strzelamy do kolejnych najblizszych wrogow (projectiles_per_attack sztuk).
	for _i in projectiles_per_attack:
		var idx := find_nearest(player.global_position, remaining, attack_range)
		if idx == -1:
			break
		var target = valid[idx]
		var harpoon = pool.get_harpoon()
		if harpoon == null:
			break
		var dir: Vector2 = (target.global_position - player.global_position).normalized()
		harpoon.fire(player.global_position, dir)
		if player.has_method("play_shoot_sound"):
			player.play_shoot_sound()
		remaining[idx] = Vector2(INF, INF) # wyklucz tego wroga z kolejnego strzalu

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
