extends SceneTree

# Debug: lodz nieruchomo, loguj kazdy spadek HP + czas + najblizszego wroga (przyczyna bug #1).

var _main: Node = null

func _initialize() -> void:
	_run()

func _run() -> void:
	_main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	var gs: Node = root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.health_changed.connect(_on_hp)
	# loguj tez spawny wrogow z dystansem do lodzi
	var spawner: Node = _main.get_node_or_null("EnemySpawner")
	var frames := 0
	var last_count := 0
	while frames < 9 * 60:
		await process_frame
		frames += 1
		var enemies := _main.get_tree().get_nodes_in_group("enemies")
		if enemies.size() > last_count:
			var boat := _main.get_node_or_null("Boat")
			for e in enemies:
				pass
			var d := 99999.0
			if boat != null and enemies.size() > 0:
				d = boat.global_position.distance_to(enemies[enemies.size() - 1].global_position)
			print("SPAWN t=%.2f n=%d dystans_ostatniego=%.0f" % [gs.time, enemies.size(), d])
			last_count = enemies.size()
		if gs.health <= 0.0:
			break
	print("KONIEC t=%.2f hp=%.1f" % [gs.time, gs.health])
	quit()

func _on_hp(h: float) -> void:
	var gs: Node = root.get_node_or_null("/root/GameState")
	var boat: Node = _main.get_node_or_null("Boat")
	var enemies := _main.get_tree().get_nodes_in_group("enemies")
	var nearest := 99999.0
	for e in enemies:
		if boat != null:
			nearest = minf(nearest, boat.global_position.distance_to(e.global_position))
	print("HP-> %.1f  t=%.2f  wrogow=%d  najblizszy=%.0f px" % [h, gs.time, enemies.size(), nearest])
