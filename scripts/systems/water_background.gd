extends ColorRect

# Tlo wody podaza za kamera, by zawsze wypelniac widok (swiat jest wiekszy niz ColorRect).
# Fale sa zakotwiczone w SWIECIE (shader czyta pozycje swiatowa przez MODEL_MATRIX), wiec
# mimo podazania prostokata woda nie "przykleja sie" do ekranu - lodz plynie nad nia.

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		global_position = cam.get_screen_center_position() - size * 0.5
