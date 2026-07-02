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

# Etykiety trybow do UI wyboru - jedno zrodlo dla ekranu ustawien i panelu pauzy.
const MODE_LABELS := {
	KEYBOARD: "Klawiatura (WASD / strzałki)",
	MOUSE_CLICK: "Mysz - płyń do kliknięcia",
	MOUSE_FOLLOW: "Mysz - podążaj za kursorem",
	TOUCH_JOYSTICK: "Joystick ekranowy",
	TOUCH_FOLLOW: "Podążaj za dotykiem",
}

# Czysta funkcja: tryby dostepne w UI wyboru per platforma.
static func allowed_modes(is_mobile: bool) -> Array[String]:
	if is_mobile:
		return [TOUCH_JOYSTICK, TOUCH_FOLLOW]
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

# Czysta funkcja-router: kierunek ruchu dla trybu; nieznane tryby -> fallback klawiatura.
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
