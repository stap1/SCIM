class_name ControlModes
extends RefCounted

# Tryby sterowania lodzia + czyste funkcje kierunku ruchu. Wybrany tryb zyje
# w SettingsStore.control_mode (persystencja); lodz (boat.gd) tlumaczy tryb na
# kierunek przez dispatch_direction - wszystkie wejscia jawne, zero singletonow.

const KEYBOARD := "keyboard"              # akcje InputMap (WASD / strzalki)
const MOUSE_CLICK := "mouse_click"        # plyn do klikniecia (click-to-follow)
const MOUSE_FOLLOW := "mouse_follow"      # podazaj za kursorem
const TOUCH_JOYSTICK := "touch_joystick"  # joystick ekranowy (mobile)
const TOUCH_FOLLOW := "touch_follow"      # podazaj za dotykiem (mobile)
const ACCEL := "accel"                    # przechyl telefonu (mobile, eksperymentalny)

# Etykiety trybow do UI wyboru - jedno zrodlo dla ekranu ustawien i panelu pauzy.
const MODE_LABELS := {
	KEYBOARD: "Klawiatura (WASD / strzałki)",
	MOUSE_CLICK: "Mysz - płyń do kliknięcia",
	MOUSE_FOLLOW: "Mysz - podążaj za kursorem",
	TOUCH_JOYSTICK: "Joystick ekranowy",
	TOUCH_FOLLOW: "Podążaj za dotykiem",
	ACCEL: "Przechył telefonu (eksperymentalne)",
}

# Czysta funkcja: tryby dostepne w UI wyboru per platforma.
static func allowed_modes(is_mobile: bool) -> Array[String]:
	if is_mobile:
		return [TOUCH_JOYSTICK, TOUCH_FOLLOW, ACCEL]
	return [KEYBOARD, MOUSE_CLICK, MOUSE_FOLLOW]

# Czysta funkcja: domyslny tryb per platforma.
static func default_control_mode(is_mobile: bool) -> String:
	return TOUCH_JOYSTICK if is_mobile else KEYBOARD

# Czysta funkcja: nieznany/cudzy tryb (np. z recznie edytowanego pliku albo zapisu
# z innej platformy) -> default platformy.
static func sanitize_control_mode(raw: String, is_mobile: bool) -> String:
	return raw if raw in allowed_modes(is_mobile) else default_control_mode(is_mobile)

# Czysta funkcja: kierunek do celu z martwa strefa - w strefie ZERO (lodz nie wibruje).
static func direction_to_target(from: Vector2, target: Vector2, deadzone_px: float) -> Vector2:
	var offset := target - from
	if offset.length() <= deadzone_px:
		return Vector2.ZERO
	return offset.normalized()

# Czysta funkcja: kierunek z galki joysticka. Ponizej martwej strefy ZERO; powyzej
# znormalizowany kierunek (o predkosci decyduje lodz, nie wychylenie).
static func direction_from_joystick(stick: Vector2, deadzone: float) -> Vector2:
	if stick.length() <= deadzone:
		return Vector2.ZERO
	return stick.normalized()

# Czysta funkcja: przechyl wzgledem punktu kalibracji (zero-point). Os X urzadzenia
# to ekranowe +x; wzrost skladowej Y akcelerometru (gorna krawedz od siebie) ma
# plynac W GORE ekranu, stad odwrocony znak.
static func tilt_from_accel(accel: Vector2, zero: Vector2) -> Vector2:
	return Vector2(accel.x - zero.x, -(accel.y - zero.y))

# Czysta funkcja: kierunek z przechylu. Martwa strefa tnie szum sensora; czulosc
# skaluje wychylenie, dlugosc przycieta do 1 (pelny przechyl = pelna predkosc).
static func direction_from_accel(tilt: Vector2, deadzone: float, sensitivity: float) -> Vector2:
	if tilt.length() <= deadzone:
		return Vector2.ZERO
	return (tilt * sensitivity).limit_length(1.0)

# Czysta funkcja-router: kierunek ruchu dla trybu. Tryb akcelerometru lodz obsluguje
# osobno (wymaga kalibracji i odczytu sensora); nieznane tryby -> fallback klawiatura.
static func dispatch_direction(mode: String, keyboard_dir: Vector2, boat_pos: Vector2,
		target_pos: Vector2, has_target: bool, target_deadzone_px: float,
		stick: Vector2, stick_deadzone: float) -> Vector2:
	match mode:
		MOUSE_CLICK, TOUCH_FOLLOW:
			if not has_target:
				return Vector2.ZERO # brak celu -> lodz stoi i czeka na klik/dotyk
			return direction_to_target(boat_pos, target_pos, target_deadzone_px)
		MOUSE_FOLLOW:
			return direction_to_target(boat_pos, target_pos, target_deadzone_px)
		TOUCH_JOYSTICK:
			return direction_from_joystick(stick, stick_deadzone)
		_:
			return keyboard_dir # KEYBOARD + bezpieczny fallback nieznanych trybow
