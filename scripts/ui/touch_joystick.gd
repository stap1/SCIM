class_name TouchJoystick
extends CanvasLayer

# Joystick ekranowy (mobile) w prawym dolnym rogu. Sledzi JEDEN palec, ktory zaczal
# dotyk w obszarze bazy, i wystawia znormalizowany wektor galki (vector) dla lodzi
# (grupa "touch_joystick" - luzne powiazanie scen). Widoczny tylko na buildzie
# mobilnym w trybie touch_joystick; reaguje na zmiane trybu na zywo (sygnal SettingsStore).

var vector: Vector2 = Vector2.ZERO
var _touch_index: int = -1

@onready var base: Control = get_node_or_null("Base")
@onready var knob: Control = get_node_or_null("Base/Knob")

func _ready() -> void:
	add_to_group("touch_joystick")
	_refresh_visibility(SettingsStore.control_mode)
	SettingsStore.control_mode_changed.connect(_refresh_visibility)

func _refresh_visibility(mode: String) -> void:
	visible = Platform.is_mobile_build() and mode == ControlModes.TOUCH_JOYSTICK
	if not visible:
		_release()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1 and _in_base(t.position):
			_touch_index = t.index
			_update_knob(t.position)
		elif not t.pressed and t.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_update_knob(d.position)

func _in_base(screen_pos: Vector2) -> bool:
	return base != null and base.get_global_rect().has_point(screen_pos)

func _update_knob(screen_pos: Vector2) -> void:
	if base == null:
		return
	var center := base.get_global_rect().get_center()
	vector = stick_vector(center, screen_pos, GameConfig.TOUCH_JOYSTICK_RADIUS_PX)
	if knob:
		knob.position = base.size / 2.0 - knob.size / 2.0 \
			+ vector * GameConfig.TOUCH_JOYSTICK_RADIUS_PX

func _release() -> void:
	_touch_index = -1
	vector = Vector2.ZERO
	if knob and base:
		knob.position = base.size / 2.0 - knob.size / 2.0

# Czysta funkcja: znormalizowany wektor galki [-1,1] z pozycji palca wzgledem srodka bazy.
static func stick_vector(center: Vector2, touch: Vector2, radius_px: float) -> Vector2:
	if radius_px <= 0.0:
		return Vector2.ZERO
	return ((touch - center) / radius_px).limit_length(1.0)
