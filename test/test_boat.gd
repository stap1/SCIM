extends GutTest

# KROK 3 (Prompt 3): ruch lodzi - test sceny + czystych funkcji (bez zaleznosci od drzewa).

const BoatScene := preload("res://scenes/player/boat.tscn")
const BoatScript := preload("res://scripts/player/boat.gd")

func test_boat_is_character_body_with_max_speed() -> void:
	var boat = BoatScene.instantiate()
	assert_true(boat is CharacterBody2D, "Boat musi byc CharacterBody2D")
	assert_eq(boat.max_speed, 200.0, "max_speed == 200.0")
	boat.free()

func test_compute_velocity_cardinal() -> void:
	assert_eq(BoatScript.compute_velocity(Vector2(1, 0), 200.0), Vector2(200, 0),
		"compute_velocity(prawo, 200) == (200, 0)")

func test_compute_velocity_diagonal_is_normalized() -> void:
	var v: Vector2 = BoatScript.compute_velocity(Vector2(1, 1), 200.0)
	assert_almost_eq(v.length(), 200.0, 0.001,
		"wektor ukosny ma dlugosc ~200 (znormalizowany przed skalowaniem)")
