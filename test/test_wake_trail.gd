extends GutTest

# Kilwater (WakeTrail): czysta funkcja parametrow smugi + dolaczenie do CharacterBody2D.
# Smuga zostaje w swiecie (local_coords=false), a jej dlugosc rosnie proporcjonalnie
# do predkosci (stale zycie czastek x szybszy ruch = dluzszy slad).

func after_each() -> void:
	GameState.reset()

# --- Czysta funkcja wake_params ---

func test_wake_params_below_threshold_not_emitting() -> void:
	var p := WakeTrail.wake_params(0.0, 200.0, 25.0, 1.8, 3.4)
	assert_false(p["emitting"], "postoj -> brak smugi")
	var p2 := WakeTrail.wake_params(24.9, 200.0, 25.0, 1.8, 3.4)
	assert_false(p2["emitting"], "ponizej progu predkosci -> brak smugi")

func test_wake_params_full_speed() -> void:
	var p := WakeTrail.wake_params(200.0, 200.0, 25.0, 1.8, 3.4)
	assert_true(p["emitting"], "pelna predkosc -> smuga")
	assert_almost_eq(p["ratio"], 1.0, 0.001, "ratio 1.0 przy predkosci referencyjnej")
	assert_almost_eq(p["particle_scale"], 3.4, 0.001, "najwieksze czastki przy pelnej predkosci")

func test_wake_params_scales_with_speed() -> void:
	var p := WakeTrail.wake_params(100.0, 200.0, 25.0, 1.8, 3.4)
	assert_almost_eq(p["ratio"], 0.5, 0.001, "polowa predkosci -> ratio 0.5")
	assert_almost_eq(p["particle_scale"], 2.6, 0.001, "rozmiar czastek liniowo miedzy min a max")

func test_wake_params_clamps_and_safe_reference() -> void:
	var p := WakeTrail.wake_params(400.0, 200.0, 25.0, 1.8, 3.4)
	assert_almost_eq(p["ratio"], 1.0, 0.001, "powyzej referencji przyciete do 1")
	var p2 := WakeTrail.wake_params(50.0, 0.0, 25.0, 1.8, 3.4)
	assert_almost_eq(p2["ratio"], 1.0, 0.001, "zerowa referencja bez dzielenia przez zero")

# --- Dolaczenie do ciala i reakcja na ruch ---

func test_attach_and_emits_only_when_moving() -> void:
	var body := CharacterBody2D.new()
	var wake := WakeTrail.attach_to(body, 8, 200.0)
	add_child_autofree(body)
	await wait_physics_frames(1)
	assert_true(is_instance_valid(wake) and wake.get_parent() == body, "kilwater dzieckiem ciala")
	assert_false(wake.local_coords, "czastki w przestrzeni swiata - smuga ZOSTAJE za jednostka")
	assert_false(wake.emitting, "bez ruchu brak smugi")
	body.velocity = Vector2(200, 0)
	await wait_physics_frames(2)
	assert_true(wake.emitting, "ruch -> smuga sie tworzy")
	body.velocity = Vector2.ZERO
	await wait_physics_frames(2)
	assert_false(wake.emitting, "zatrzymanie -> smuga gasnie")
