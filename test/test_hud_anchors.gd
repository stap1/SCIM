extends GutTest

# QA #2: HUD nie wykracza poza ekran. HUD jest w CanvasLayer (poprawnie), wiec naprawa
# to KOTWICE: prawa kolumna przyklejona do prawej krawedzi, ostrzezenie do srodka.
# Dodatkowo tryb stretch w project.godot daje niezaleznosc od rozdzielczosci.

const HUDScene := preload("res://scenes/ui/hud.tscn")

# --- Kotwice: prawa kolumna przyklejona do prawej krawedzi ---

func test_right_column_anchored_to_right() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	for node_name in ["HealthBar", "LevelLabel", "XPBar"]:
		var node: Control = hud.get_node(node_name)
		assert_almost_eq(node.anchor_left, 1.0, 0.001, "%s.anchor_left = 1 (prawa krawedz)" % node_name)
		assert_almost_eq(node.anchor_right, 1.0, 0.001, "%s.anchor_right = 1 (prawa krawedz)" % node_name)
		assert_lt(node.offset_right, 0.0, "%s offset_right ujemny (margines od prawej)" % node_name)

func test_boss_warning_centered() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	var warn: Control = hud.get_node("BossWarning")
	assert_almost_eq(warn.anchor_left, 0.5, 0.001, "BossWarning kotwiczony do srodka")
	assert_almost_eq(warn.anchor_right, 0.5, 0.001, "BossWarning kotwiczony do srodka")

# --- Niezaleznosc od rozdzielczosci (project.godot) ---

func test_stretch_mode_canvas_items() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items",
		"stretch canvas_items - UI skaluje sie z oknem")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand",
		"aspect expand - szersze ekrany pokazuja wiecej, zamiast ucinac HUD")

func test_base_viewport_size() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1152,
		"bazowa szerokosc viewportu")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 648,
		"bazowa wysokosc viewportu")
