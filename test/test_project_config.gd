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

func test_main_scene_points_to_main_tscn() -> void:
	assert_eq(_resolve_main_scene(), "res://scenes/Main.tscn",
		"run/main_scene musi wskazywac res://scenes/Main.tscn (NIGDY HUD ani inna scene)")

func test_main_scene_file_exists() -> void:
	assert_true(ResourceLoader.exists("res://scenes/Main.tscn"),
		"Plik res://scenes/Main.tscn musi istniec")

func test_game_state_autoload_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GameState"),
		"GameState musi byc zarejestrowany jako autoload (jedyne zrodlo prawdy)")
