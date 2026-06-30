extends Control

# Ekran historii zmian - tekst czytany z ChangelogData (najnowsze na gorze). Powrot do menu.

@onready var list_label: Label = get_node_or_null("Panel/Scroll/ChangelogList")
@onready var back_button: Button = get_node_or_null("Panel/BackButton")

func _ready() -> void:
	if list_label:
		list_label.text = ChangelogData.format_all()
	if back_button:
		back_button.pressed.connect(_on_back)
		back_button.grab_focus() # nawigacja klawiatura

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC -> powrot do menu
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
