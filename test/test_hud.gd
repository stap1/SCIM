extends GutTest

# KROK 7 (Prompt 7): HUD read-only czytajacy GameState przez sygnaly.

const HUDScene := preload("res://scenes/ui/hud.tscn")
const HudScript := preload("res://scripts/ui/hud.gd")

func before_each() -> void:
	GameState.health = GameState.max_health

func test_format_time() -> void:
	assert_eq(HudScript.format_time(75.0), "01:15", "format_time(75.0) == 01:15")
	assert_eq(HudScript.format_time(5.0), "00:05", "format_time(5.0) == 00:05")

func test_health_bar_updates_on_signal() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	GameState.health_changed.emit(50.0)
	var bar: ProgressBar = hud.get_node("HealthBar")
	assert_eq(bar.value, 50.0, "HealthBar.value == 50 po emisji health_changed(50)")

func test_score_label_updates_on_signal() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	GameState.score_changed.emit(42)
	var label: Label = hud.get_node("ScoreLabel")
	assert_true(label.text.find("42") != -1, "ScoreLabel pokazuje wynik po score_changed")
