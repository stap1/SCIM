extends GutTest

# KROK 20 (Prompt 20): ustawienia - slider_to_db, round-trip ConfigFile, scena startowa.

const SettingsScript := preload("res://scripts/ui/settings.gd")

func test_slider_to_db() -> void:
	assert_almost_eq(SettingsScript.slider_to_db(1.0), 0.0, 0.001, "slider_to_db(1.0) == 0 db")
	assert_true(SettingsScript.slider_to_db(0.0) <= -60.0, "slider_to_db(0.0) <= -60 db")

func test_config_round_trip() -> void:
	var path := "user://test_settings.cfg"
	SettingsScript.save_settings(path, 0.3, 0.7, 20)
	var s := SettingsScript.load_settings(path)
	assert_almost_eq(s["music_vol"], 0.3, 0.001, "music_vol round-trip")
	assert_almost_eq(s["sfx_vol"], 0.7, 0.001, "sfx_vol round-trip")
	assert_eq(int(s["session_length"]), 20, "session_length round-trip")

func test_main_scene_is_main_menu() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"),
		"res://scenes/MainMenu.tscn", "scena startowa to MainMenu")
