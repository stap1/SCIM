extends GutTest

# Modul sterowania: taksonomia trybow (per platforma) + czyste funkcje kierunku ruchu.
# Router dispatch_direction dostaje wszystko jawnie (zero singletonow) - pelna testowalnosc.

func test_allowed_modes_per_platform() -> void:
	var desktop := ControlModes.allowed_modes(false)
	assert_true(ControlModes.KEYBOARD in desktop and ControlModes.MOUSE_CLICK in desktop
		and ControlModes.MOUSE_FOLLOW in desktop, "desktop: klawiatura + dwa tryby myszy")
	assert_false(ControlModes.TOUCH_JOYSTICK in desktop, "desktop bez trybow dotykowych")
	var mobile := ControlModes.allowed_modes(true)
	assert_true(ControlModes.TOUCH_JOYSTICK in mobile and ControlModes.TOUCH_FOLLOW in mobile,
		"mobile: joystick + podazanie za dotykiem")
	assert_false(ControlModes.KEYBOARD in mobile, "mobile bez klawiatury")
	assert_false("accel" in mobile, "akcelerometr usuniety - brak trybu accel")

func test_default_mode_per_platform() -> void:
	assert_eq(ControlModes.default_control_mode(false), ControlModes.KEYBOARD, "desktop -> klawiatura")
	assert_eq(ControlModes.default_control_mode(true), ControlModes.TOUCH_JOYSTICK, "mobile -> joystick")

func test_sanitize_mode() -> void:
	assert_eq(ControlModes.sanitize_control_mode(ControlModes.MOUSE_CLICK, false),
		ControlModes.MOUSE_CLICK, "poprawny tryb zostaje")
	assert_eq(ControlModes.sanitize_control_mode("smiec_z_pliku", false),
		ControlModes.KEYBOARD, "nieznany tryb -> default platformy")
	assert_eq(ControlModes.sanitize_control_mode(ControlModes.KEYBOARD, true),
		ControlModes.TOUCH_JOYSTICK, "tryb desktopowy na mobile -> default mobile")
	assert_eq(ControlModes.sanitize_control_mode("", false),
		ControlModes.KEYBOARD, "pusty zapis -> default platformy")
	assert_eq(ControlModes.sanitize_control_mode("accel", true),
		ControlModes.TOUCH_JOYSTICK, "stary zapis 'accel' (tryb usuniety) -> default mobile")

func test_every_mode_has_ui_label() -> void:
	for m in ControlModes.allowed_modes(false) + ControlModes.allowed_modes(true):
		assert_true(ControlModes.MODE_LABELS.has(m), "etykieta UI dla trybu: %s" % m)

func test_direction_to_target() -> void:
	assert_eq(ControlModes.direction_to_target(Vector2.ZERO, Vector2(100, 0), 12.0),
		Vector2.RIGHT, "daleki cel -> znormalizowany kierunek")
	assert_eq(ControlModes.direction_to_target(Vector2.ZERO, Vector2(8, 0), 12.0),
		Vector2.ZERO, "cel w martwej strefie -> ZERO (lodz nie wibruje)")
	assert_eq(ControlModes.direction_to_target(Vector2(5, 5), Vector2(5, 5), 12.0),
		Vector2.ZERO, "cel = pozycja -> ZERO")

func test_direction_from_joystick() -> void:
	assert_eq(ControlModes.direction_from_joystick(Vector2(0.1, 0), 0.2),
		Vector2.ZERO, "wychylenie ponizej martwej strefy -> ZERO")
	assert_eq(ControlModes.direction_from_joystick(Vector2(0, 0.9), 0.2),
		Vector2.DOWN, "wychylenie -> znormalizowany kierunek (predkosc reguluje lodz)")

func test_dispatch_keyboard_and_unknown_fallback() -> void:
	var kb := Vector2(1, 0)
	assert_eq(ControlModes.dispatch_direction(ControlModes.KEYBOARD, kb,
		Vector2.ZERO, Vector2.ZERO, false, 12.0, Vector2.ZERO, 0.2), kb,
		"keyboard -> wejscie z akcji InputMap")
	assert_eq(ControlModes.dispatch_direction("nieznany_tryb", kb,
		Vector2.ZERO, Vector2.ZERO, false, 12.0, Vector2.ZERO, 0.2), kb,
		"nieznany tryb -> bezpieczny fallback na klawiature")

func test_dispatch_mouse_click_needs_target() -> void:
	assert_eq(ControlModes.dispatch_direction(ControlModes.MOUSE_CLICK, Vector2.RIGHT,
		Vector2.ZERO, Vector2.ZERO, false, 12.0, Vector2.ZERO, 0.2), Vector2.ZERO,
		"brak celu -> lodz stoi (klawiatura ignorowana w trybie myszy)")
	assert_eq(ControlModes.dispatch_direction(ControlModes.MOUSE_CLICK, Vector2.ZERO,
		Vector2.ZERO, Vector2(0, 100), true, 12.0, Vector2.ZERO, 0.2), Vector2.DOWN,
		"cel klikniecia -> kierunek do celu")
	assert_eq(ControlModes.dispatch_direction(ControlModes.MOUSE_CLICK, Vector2.ZERO,
		Vector2.ZERO, Vector2(0, 5), true, 12.0, Vector2.ZERO, 0.2), Vector2.ZERO,
		"cel osiagniety (martwa strefa) -> ZERO")

func test_dispatch_follow_and_touch() -> void:
	assert_eq(ControlModes.dispatch_direction(ControlModes.MOUSE_FOLLOW, Vector2.ZERO,
		Vector2.ZERO, Vector2(100, 0), false, 24.0, Vector2.ZERO, 0.2), Vector2.RIGHT,
		"follow-cursor: kierunek do kursora bez klikania")
	assert_eq(ControlModes.dispatch_direction(ControlModes.TOUCH_FOLLOW, Vector2.ZERO,
		Vector2.ZERO, Vector2(100, 0), true, 12.0, Vector2.ZERO, 0.2), Vector2.RIGHT,
		"follow-touch: kierunek do punktu dotyku")
	assert_eq(ControlModes.dispatch_direction(ControlModes.TOUCH_FOLLOW, Vector2.ZERO,
		Vector2.ZERO, Vector2(100, 0), false, 12.0, Vector2.ZERO, 0.2), Vector2.ZERO,
		"follow-touch bez celu -> lodz stoi")

func test_dispatch_joystick() -> void:
	assert_eq(ControlModes.dispatch_direction(ControlModes.TOUCH_JOYSTICK, Vector2.ZERO,
		Vector2.ZERO, Vector2.ZERO, false, 12.0, Vector2(0.9, 0), 0.2), Vector2.RIGHT,
		"joystick: kierunek z wychylenia galki")
	assert_eq(ControlModes.dispatch_direction(ControlModes.TOUCH_JOYSTICK, Vector2.RIGHT,
		Vector2.ZERO, Vector2.ZERO, false, 12.0, Vector2.ZERO, 0.2), Vector2.ZERO,
		"joystick w spoczynku -> ZERO (klawiatura ignorowana)")
