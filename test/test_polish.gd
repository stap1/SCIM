extends GutTest

# KROK 22 (Prompt 22) - GATE 3: accessibility (czyste flagi) + smoke MainMenu.

const SettingsScript := preload("res://scripts/ui/settings.gd")
const MainMenuScene := preload("res://scenes/MainMenu.tscn")

func test_should_apply_shake() -> void:
	assert_false(SettingsScript.should_apply_shake(true), "reduce wlaczone -> bez shake")
	assert_true(SettingsScript.should_apply_shake(false), "reduce wylaczone -> shake gra")

func test_should_flash() -> void:
	assert_false(SettingsScript.should_flash(true), "reduce wlaczone -> bez flash")
	assert_true(SettingsScript.should_flash(false), "reduce wylaczone -> flash gra")

func test_settings_round_trip_includes_accessibility() -> void:
	var path := "user://test_polish_settings.cfg"
	SettingsScript.save_settings(path, 0.5, 0.5, 15, true, true)
	var s := SettingsScript.load_settings(path)
	assert_true(bool(s["reduce_shake"]), "reduce_shake round-trip")
	assert_true(bool(s["reduce_flashing"]), "reduce_flashing round-trip")

func test_main_menu_smoke() -> void:
	var menu = MainMenuScene.instantiate()
	add_child_autofree(menu)
	await wait_physics_frames(10)
	assert_true(is_instance_valid(menu), "MainMenu.tscn dziala kilka klatek bez crasha")
