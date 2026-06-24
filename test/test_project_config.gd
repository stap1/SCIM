extends GutTest

# KROK 1 (Prompt 1) + REGRESJA #1: wskaznik glownej sceny.
# Pilnuje bledu, ktory juz raz wystapil - main_scene nie moze wskazywac
# HUD ani innej sceny. Kroki 1-19: Main.tscn (od kroku 20: MainMenu.tscn).

func _resolve_main_scene() -> String:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	# Godot moze zapisac wskaznik jako UID - rozwiazujemy go do sciezki res://.
	if main_scene.begins_with("uid://"):
		var id: int = ResourceUID.text_to_id(main_scene)
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return main_scene

func test_main_scene_points_to_main_menu() -> void:
	# Od kroku 20 scena startowa to MainMenu (wczesniej Main). NIGDY HUD ani inna scena.
	assert_eq(_resolve_main_scene(), "res://scenes/MainMenu.tscn",
		"run/main_scene musi wskazywac res://scenes/MainMenu.tscn (od kroku 20)")

func test_main_scene_file_exists() -> void:
	assert_true(ResourceLoader.exists("res://scenes/MainMenu.tscn"),
		"Plik res://scenes/MainMenu.tscn musi istniec")
	# Main.tscn nadal istnieje - MainMenu laduje ja przyciskiem Start.
	assert_true(ResourceLoader.exists("res://scenes/Main.tscn"),
		"Plik res://scenes/Main.tscn musi istniec (ladowany ze Start)")

func test_game_state_autoload_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GameState"),
		"GameState musi byc zarejestrowany jako autoload (jedyne zrodlo prawdy)")

# REGRESJA: rozmiar okna i vsync zniknely przypadkiem przy re-serializacji edytora
# (commit audio 9bf539c). Pilnuje, by ustawienia display nie wyparowaly ponownie.
func test_display_window_size_and_vsync() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1152,
		"viewport_width musi byc 1152")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 648,
		"viewport_height musi byc 648")
	assert_eq(int(ProjectSettings.get_setting("display/window/vsync/vsync_mode")), 1,
		"vsync_mode musi byc 1 (wlaczony)")
