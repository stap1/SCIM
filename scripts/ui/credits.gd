extends Control

# Ekran CREDITS: autorzy, zrodla assetow i ich autorzy, podziekowania, wzmianka o AI.
# Tresc w RichTextLabel (scena). Przycisk powrotu wraca do menu glownego.

func _ready() -> void:
	var back := get_node_or_null("Panel/BackButton")
	if back:
		back.pressed.connect(_on_back)
		back.grab_focus()  # nawigacja klawiatura

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
