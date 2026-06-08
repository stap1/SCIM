extends GutTest

# P2.2: ruch gracza przez akcje InputMap (zamiast sztywnych KEY_*).
# Umozliwia remapowanie i sterowanie mobilne (przyciski dotykowe emituja te same akcje).

const BoatScript := preload("res://scripts/player/boat.gd")

# Kazda akcja ma byc zwiazana z klawiszem WSAD oraz odpowiednika strzalka.
const ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
}

func test_actions_exist() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), "InputMap ma akcje %s" % action)

func test_actions_bind_wasd_and_arrows() -> void:
	for action in ACTIONS:
		var phys: Array = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				phys.append(ev.physical_keycode)
		for expected in ACTIONS[action]:
			assert_true(expected in phys,
				"%s zwiazane z klawiszem fizycznym %d" % [action, expected])

# --- Czysta funkcja kierunku (testowalna bez globalnego Input) ---

func test_direction_from_input_basic() -> void:
	assert_eq(BoatScript.direction_from_input(false, false, false, false), Vector2.ZERO, "brak wejscia -> zero")
	assert_eq(BoatScript.direction_from_input(true, false, false, false), Vector2.RIGHT, "right")
	assert_eq(BoatScript.direction_from_input(false, true, false, false), Vector2.LEFT, "left")
	assert_eq(BoatScript.direction_from_input(false, false, true, false), Vector2.DOWN, "down")
	assert_eq(BoatScript.direction_from_input(false, false, false, true), Vector2.UP, "up")

func test_direction_opposites_cancel() -> void:
	assert_eq(BoatScript.direction_from_input(true, true, false, false), Vector2.ZERO, "right+left -> zero")
	assert_eq(BoatScript.direction_from_input(false, false, true, true), Vector2.ZERO, "down+up -> zero")

func test_direction_diagonal_normalized() -> void:
	# right + up: ukos nie moze byc szybszy niz ruch prosty (dlugosc 1).
	var d := BoatScript.direction_from_input(true, false, false, true)
	assert_almost_eq(d.length(), 1.0, 0.001, "ukos znormalizowany do dlugosci 1")

# --- Straznik regresji: boat nie czyta juz sztywnych klawiszy ---

func test_boat_uses_input_actions_not_raw_keys() -> void:
	var f := FileAccess.open("res://scripts/player/boat.gd", FileAccess.READ)
	assert_not_null(f, "boat.gd istnieje")
	if f:
		var src := f.get_as_text()
		f.close()
		assert_false(src.contains("is_key_pressed"),
			"boat.gd nie uzywa sztywnych KEY_* (ruch przez akcje InputMap)")
		assert_true(src.contains("is_action_pressed"),
			"boat.gd czyta akcje InputMap")
