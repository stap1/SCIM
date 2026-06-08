extends GutTest

# KROK 4 (Prompt 4): kamera sledzaca lodz.
# REGRESJA: Camera2D MUSI miec enabled=true - wczesniejszy blad projektu
# polegal na wylaczonej kamerze dajacej statyczny ekran. Nie powtarzac.

const BoatScene := preload("res://scenes/player/boat.tscn")

func test_boat_has_camera() -> void:
	var boat = BoatScene.instantiate()
	var cam := boat.get_node_or_null("Camera2D")
	assert_not_null(cam, "Boat musi miec dziecko Camera2D")
	boat.free()

func test_camera_enabled() -> void:
	var boat = BoatScene.instantiate()
	var cam: Camera2D = boat.get_node_or_null("Camera2D")
	assert_true(cam.enabled, "Camera2D.enabled musi byc true (inaczej statyczny ekran)")
	boat.free()

func test_camera_position_smoothing_enabled() -> void:
	var boat = BoatScene.instantiate()
	var cam: Camera2D = boat.get_node_or_null("Camera2D")
	assert_true(cam.position_smoothing_enabled, "position_smoothing_enabled musi byc true")
	boat.free()
