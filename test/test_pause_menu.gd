extends GutTest

# QA #1: menu pauzy (Wznow / Restart / Menu) na natywnej pauzie Godota.
# Wzorzec "jeden wlasciciel pauzy": menu pauzuje tylko w aktywnej rozgrywce.

const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")

func before_each() -> void:
	GameState.reset()

func after_each() -> void:
	# Bezpiecznik: menu pauzuje DRZEWO - nigdy nie zostawiaj go wstrzymanego.
	get_tree().paused = false
	GameState.is_game_over = false

func _menu() -> Node:
	var pm = PauseMenuScene.instantiate()
	add_child_autofree(pm)
	return pm

func test_loads_always_and_hidden() -> void:
	var pm = _menu()
	await wait_physics_frames(1)
	assert_eq(pm.process_mode, Node.PROCESS_MODE_ALWAYS, "menu dziala mimo get_tree().paused")
	assert_false(pm.get_node("Dimmer").visible, "na starcie menu ukryte")

func test_toggle_opens_in_active_play() -> void:
	var pm = _menu()
	await wait_physics_frames(1)
	pm.toggle()
	assert_true(get_tree().paused, "drzewo wstrzymane po otwarciu pauzy")
	assert_true(GameState.is_paused, "GameState.is_paused ustawione na pauzie")
	assert_true(pm.get_node("Dimmer").visible, "menu widoczne")

func test_toggle_again_resumes() -> void:
	var pm = _menu()
	await wait_physics_frames(1)
	pm.toggle() # otworz
	pm.toggle() # wznow
	assert_false(get_tree().paused, "drzewo wznowione")
	assert_false(GameState.is_paused, "is_paused zdjete")
	assert_false(pm.get_node("Dimmer").visible, "menu ukryte")

func test_resume_button_path() -> void:
	var pm = _menu()
	await wait_physics_frames(1)
	pm.toggle()
	pm.resume()
	assert_false(get_tree().paused, "przycisk Wznow zdejmuje pauze")

func test_no_pause_during_game_over() -> void:
	var pm = _menu()
	await wait_physics_frames(1)
	GameState.is_game_over = true
	pm.toggle()
	assert_false(get_tree().paused, "po game over klawisz pauzy ignorowany")
	assert_false(pm.get_node("Dimmer").visible, "menu sie nie otwiera po game over")

func test_does_not_steal_foreign_pause() -> void:
	# Symulacja: drzewo wstrzymane przez inny ekran (np. wybor ulepszenia).
	var pm = _menu()
	await wait_physics_frames(1)
	get_tree().paused = true
	pm.toggle()
	assert_true(get_tree().paused, "menu nie zdejmuje cudzej pauzy")
	assert_false(pm.get_node("Dimmer").visible, "menu nie otwiera sie nad cudza pauza")
