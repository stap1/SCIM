extends GutTest

# QA #5: mini-boss nie jest juz statycznym obrazem - plynnie obraca sie ku celowi
# (lerp_angle, najkrotsza droga, bez przeskoku przez owijanie 2*PI).

const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")
const MotorBoatScript := preload("res://scripts/systems/motor_boat.gd")

func before_each() -> void:
	GameState.reset()

# --- Czysta funkcja obrotu ---

func test_aim_rotation_moves_toward_target() -> void:
	var r := MotorBoatScript.aim_rotation(0.0, PI / 2.0, 6.0, 0.1)
	assert_gt(r, 0.0, "obrot rusza ku celowi")
	assert_lt(r, PI / 2.0, "ale go nie przeskakuje w jednej klatce")

func test_aim_rotation_full_weight_reaches_target() -> void:
	# turn_speed * delta >= 1 -> waga przycieta do 1 -> dochodzi do celu.
	var r := MotorBoatScript.aim_rotation(0.0, 1.0, 100.0, 1.0)
	assert_almost_eq(r, 1.0, 0.001, "pelna waga -> kat docelowy")

func test_aim_rotation_shortest_path_no_wrap_jump() -> void:
	# Z 170 do -170 stopni najkrotsza droga wiedzie przez 180, nie przez 0.
	var from := deg_to_rad(170.0)
	var to := deg_to_rad(-170.0)
	var r := MotorBoatScript.aim_rotation(from, to, 6.0, 0.1)
	assert_gt(absf(r), deg_to_rad(170.0),
		"obrot idzie 'na zewnatrz' (przez 180), bez przeskoku przez zero")

# --- Integracja: boss faktycznie sie obraca ---

func test_boss_rotates_toward_target_over_time() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	var dummy := Node2D.new()
	dummy.global_position = Vector2(500, 0)
	add_child_autofree(dummy)
	boss.set_target(dummy)
	boss.rotation = 0.0
	await wait_physics_frames(10)
	assert_ne(boss.rotation, 0.0, "boss obraca sie ku celowi (nie jest statycznym obrazem)")

func test_turn_speed_from_config() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	# Stala balansu w GameConfig (bez magic numbers w logice).
	assert_almost_eq(GameConfig.MINIBOSS_TURN_SPEED, 6.0, 0.001, "MINIBOSS_TURN_SPEED z GameConfig")
