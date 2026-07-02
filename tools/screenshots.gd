extends SceneTree

# Narzedzie zrzutow (uruchamiac BEZ --headless, by GPU wyrenderowalo shadery):
#   Godot --path SCIM -s res://tools/screenshots.gd
# Laduje kolejno sceny/stany, renderuje i zapisuje PNG do res://shots/.

const SHOT_DIR := "res://shots/"

func _initialize() -> void:
	_run()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	root.size = Vector2i(1152, 648)
	await _settle(3)
	await _shot_menu()
	await _shot_levelup()
	await _shot_gameover()
	await _shot_scores()
	await _shot_settings()
	quit()

func _shot_gameover() -> void:
	var s: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(s)
	await _settle(8)
	var gs: Node = root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.score = 1234
		gs.enemies_killed = 42
		gs.miniboss_defeated = true
		gs.trigger_game_over()
	await _settle(14)
	await _save("gameover")
	s.free()
	await _settle(2)

func _shot_scores() -> void:
	var s: Node = load("res://scenes/Scores.tscn").instantiate()
	root.add_child(s)
	await _settle(12)
	await _save("scores")
	s.free()
	await _settle(2)

func _shot_settings() -> void:
	var s: Node = load("res://scenes/Settings.tscn").instantiate()
	root.add_child(s)
	await _settle(12)
	await _save("settings")
	s.free()
	await _settle(2)

func _shot_enemies() -> void:
	var s: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(s)
	await _settle(8)
	var boat: Node = s.get_node_or_null("Boat")
	var specs := [
		["res://scenes/enemies/barracuda.tscn", Vector2(-150, -150)],
		["res://scenes/enemies/shark.tscn", Vector2(160, -170)],
		["res://scenes/enemies/enemy.tscn", Vector2(-40, 170)],
		["res://scenes/enemies/barracuda.tscn", Vector2(200, 70)],
	]
	for sp in specs:
		var e: Node = load(sp[0]).instantiate()
		s.add_child(e)
		if boat != null:
			e.global_position = boat.global_position + sp[1]
			if e.has_method("set_target"):
				e.set_target(boat)
	await _settle(45)  # niech sie obroca paszcza ku lodzi + plyna
	await _save("enemies")
	s.free()
	await _settle(2)

func _shot_hp_low() -> void:
	var s: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(s)
	await _settle(8)
	var gs: Node = root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.health = 32.0
		gs.health_changed.emit(32.0)
	await _settle(6)
	await _save("hp_low")
	s.free()
	await _settle(2)

func _shot_bosswarn() -> void:
	var s: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(s)
	await _settle(8)
	var gs: Node = root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.boss_incoming.emit()
	await _settle(6)
	await _save("bosswarn")
	s.free()
	await _settle(2)

func _settle(frames: int) -> void:
	for i in frames:
		await process_frame

func _save(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(SHOT_DIR + shot_name + ".png")
	print("SHOT ", shot_name)

func _clear() -> void:
	for c in root.get_children():
		c.free()

func _shot_menu() -> void:
	var s: Node = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(s)
	await _settle(15)
	await _save("menu")
	s.free()
	await _settle(2)

func _shot_water() -> void:
	var s: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(s)
	await _settle(45)  # niech woda poanimuje (karencja = brak wrogow)
	await _save("water")
	s.free()
	await _settle(2)

func _shot_telegraph() -> void:
	var s: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(s)
	await _settle(10)
	var boat: Node = s.get_node_or_null("Boat")
	var boss: Node = load("res://scenes/enemies/motor_boat.tscn").instantiate()
	s.add_child(boss)
	if boat != null:
		boss.global_position = boat.global_position + Vector2(180, 120)
		if boss.has_method("set_target"):
			boss.set_target(boat)
	await _settle(6)
	if boss.has_method("_begin_telegraph"):
		boss._begin_telegraph()
	await _settle(18)  # telegraf narasta, jeszcze przed szarza
	await _save("telegraph")
	s.free()
	await _settle(2)

func _shot_levelup() -> void:
	var lu: Node = load("res://scenes/ui/level_up.tscn").instantiate()
	root.add_child(lu)
	await _settle(5)
	var gs: Node = root.get_node_or_null("/root/GameState")
	if gs != null:
		gs.level_up.emit(2)  # panel z 3 kartami + ikonami
	await _settle(18)
	await _save("levelup")
	self.paused = false
	lu.free()
	await _settle(2)
