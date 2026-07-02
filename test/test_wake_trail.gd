extends GutTest

# Kilwater (WakeTrail): DWA slady rozchodzace sie w "V" za jednostka. Czyste funkcje
# (parametry smugi, pozycje burt, dryf na zewnatrz) + dolaczenie do CharacterBody2D.
# Rozstaw sladow = szerokosc zrodla (CollisionShape2D); kat V staly (dryf ~ predkosc);
# dlugosc sladu proporcjonalna do predkosci (stale zycie czastek).

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

# --- Czyste funkcje geometrii "V": burty i dryf na zewnatrz ---

func test_side_offsets_perpendicular_and_mirrored() -> void:
	var offs := WakeTrail.side_offsets(Vector2(100, 0), 16.0)
	assert_eq(offs.size(), 2, "dwa slady - lewa i prawa burta")
	assert_almost_eq(offs[0].distance_to(Vector2(0, -16)), 0.0, 0.001, "lewa burta prostopadle do ruchu")
	assert_almost_eq(offs[1].distance_to(Vector2(0, 16)), 0.0, 0.001, "prawa burta lustrzanie")
	assert_eq(offs[0], -offs[1], "burty symetryczne wzgledem osi ruchu")

func test_side_offsets_zero_velocity_safe() -> void:
	var offs := WakeTrail.side_offsets(Vector2.ZERO, 16.0)
	assert_eq(offs[0], Vector2.ZERO, "postoj -> brak przesuniecia (bez normalizacji zera)")
	assert_eq(offs[1], Vector2.ZERO, "postoj -> brak przesuniecia")

func test_spread_velocity_outward_constant_angle() -> void:
	var v := Vector2(200, 0)
	var left := WakeTrail.spread_velocity(v, -1.0, 0.3)
	var right := WakeTrail.spread_velocity(v, 1.0, 0.3)
	assert_almost_eq(left.length(), 60.0, 0.001, "dryf = predkosc * wspolczynnik -> staly kat V")
	assert_eq(left, -right, "dryf lustrzany na obie burty")
	assert_almost_eq(absf(left.dot(v.normalized())), 0.0, 0.001, "dryf prostopadly do kierunku ruchu")
	var slow := WakeTrail.spread_velocity(Vector2(100, 0), 1.0, 0.3)
	assert_almost_eq(slow.length(), 30.0, 0.001, "wolniejsza jednostka -> proporcjonalnie mniejszy dryf")

# --- Szerokosc zrodla z kolizji: szersza jednostka -> szerszy kilwater ---

func test_body_half_width_from_circle_shape() -> void:
	var body := CharacterBody2D.new()
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	cs.shape = circle
	body.add_child(cs)
	assert_almost_eq(WakeTrail.body_half_width(body), 20.0, 0.001, "kolo -> promien jako pol-szerokosc")
	body.free()

func test_body_half_width_from_rectangle_shape() -> void:
	var body := CharacterBody2D.new()
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 20)
	cs.shape = rect
	body.add_child(cs)
	assert_almost_eq(WakeTrail.body_half_width(body), 24.0, 0.001, "prostokat -> polowa szerokosci X")
	body.free()

func test_body_half_width_fallback_without_shape() -> void:
	var body := CharacterBody2D.new()
	assert_almost_eq(WakeTrail.body_half_width(body), GameConfig.WAKE_WIDTH_FALLBACK / 2.0, 0.001,
		"brak kolizji -> bezpieczny fallback z GameConfig")
	body.free()

# --- Dolaczenie do ciala: dwa emitery na burtach, emisja tylko w ruchu ---

func test_attach_builds_two_world_space_emitters() -> void:
	var body := CharacterBody2D.new()
	var wake := WakeTrail.attach_to(body, 8, 200.0)
	add_child_autofree(body)
	await wait_physics_frames(1)
	var emitters: Array = wake.get_children().filter(func(c): return c is CPUParticles2D)
	assert_eq(emitters.size(), 2, "dwa emitery - lewa i prawa burta")
	for e in emitters:
		assert_false(e.local_coords, "czastki w przestrzeni swiata - slad ZOSTAJE za jednostka")
	assert_false(emitters[0].emitting, "bez ruchu brak smugi")

func test_attach_emits_mirrored_when_moving() -> void:
	var body := CharacterBody2D.new()
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	cs.shape = circle
	body.add_child(cs)
	var wake := WakeTrail.attach_to(body, 8, 200.0)
	add_child_autofree(body)
	await wait_physics_frames(1)
	body.velocity = Vector2(200, 0)
	await wait_physics_frames(2)
	var emitters: Array = wake.get_children().filter(func(c): return c is CPUParticles2D)
	assert_true(emitters[0].emitting and emitters[1].emitting, "ruch -> oba slady aktywne")
	var d0: float = emitters[0].global_position.y - body.global_position.y
	var d1: float = emitters[1].global_position.y - body.global_position.y
	assert_almost_eq(d0, -16.0, 0.5, "lewy emiter na burcie (prostopadle do ruchu)")
	assert_almost_eq(d1, 16.0, 0.5, "prawy emiter na przeciwnej burcie")
	body.velocity = Vector2.ZERO
	await wait_physics_frames(2)
	assert_false(emitters[0].emitting or emitters[1].emitting, "zatrzymanie -> smuga gasnie")
