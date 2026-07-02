extends MenuScreen

# Ekran CREDITS: autorzy, zrodla assetow i ich autorzy, podziekowania, wzmianka o AI.
# Tresc w RichTextLabel (scena). Powrot/ESC: baza MenuScreen.

func _ready() -> void:
	super()
	# Build pionowy: zwez panel i tresc do szerokosci ekranu (desktop zostaje szeroki).
	if Platform.is_mobile_build():
		var panel := get_node_or_null("Panel") as Control
		if panel:
			panel.offset_left = -280.0
			panel.offset_right = 280.0
		var body := get_node_or_null("Panel/Body") as Control
		if body:
			body.custom_minimum_size = Vector2(560, 400)
