extends GutTest

# Joystick ekranowy (mobile): czysta funkcja wektora galki + smoke sceny + grupa
# (lodz znajduje joystick przez grupe "touch_joystick" - luzne powiazanie scen).

const JoyScene := preload("res://scenes/ui/touch_joystick.tscn")

func test_stick_vector_center_is_zero() -> void:
	assert_eq(TouchJoystick.stick_vector(Vector2(100, 100), Vector2(100, 100), 50.0),
		Vector2.ZERO, "palec w srodku bazy -> ZERO")

func test_stick_vector_clamped_to_unit() -> void:
	var v := TouchJoystick.stick_vector(Vector2(100, 100), Vector2(300, 100), 50.0)
	assert_almost_eq(v.x, 1.0, 0.001, "wychylenie poza promien -> przyciete do 1")
	assert_almost_eq(v.y, 0.0, 0.001, "kierunek czysto poziomy")

func test_stick_vector_proportional_inside_radius() -> void:
	assert_almost_eq(TouchJoystick.stick_vector(Vector2.ZERO, Vector2(0, 25), 50.0).y, 0.5, 0.001,
		"polowa promienia -> wychylenie 0.5")

func test_stick_vector_zero_radius_safe() -> void:
	assert_eq(TouchJoystick.stick_vector(Vector2.ZERO, Vector2(10, 0), 0.0), Vector2.ZERO,
		"zerowy promien -> ZERO (brak dzielenia przez zero)")

func test_scene_smoke_group_and_idle_vector() -> void:
	var j = JoyScene.instantiate()
	add_child_autofree(j)
	await wait_physics_frames(1)
	assert_true(is_instance_valid(j), "touch_joystick.tscn laduje bez crasha")
	assert_true(j.is_in_group("touch_joystick"), "joystick w grupie touch_joystick")
	assert_eq(j.vector, Vector2.ZERO, "bez dotyku wektor zerowy")
	assert_false(j.visible, "na desktopie (testy) joystick ukryty")
