extends GutTest

# Kilwater po przebudowie wydajnosciowej: jednostki odkladaja STEMPLE piany do
# wspolnego WakeField (jeden rysownik, ring buffer z twardym limitem) co
# WAKE_SPACING_PX przebytej DROGI. Odstep z drogi = rowna linia niezaleznie od
# predkosci (koniec "kropek" barakudy); limit stempli = sufit kosztu przy stadzie.

func after_each() -> void:
	GameState.reset()

# --- Czysta funkcja wake_params ---

func test_wake_params_below_threshold_not_emitting() -> void:
	var p := WakeTrail.wake_params(0.0, 200.0, 25.0, 0.35, 0.75)
	assert_false(p["emitting"], "postoj -> brak smugi")
	var p2 := WakeTrail.wake_params(24.9, 200.0, 25.0, 0.35, 0.75)
	assert_false(p2["emitting"], "ponizej progu predkosci -> brak smugi")

func test_wake_params_scales_with_speed() -> void:
	var p := WakeTrail.wake_params(200.0, 200.0, 25.0, 0.35, 0.75)
	assert_true(p["emitting"], "pelna predkosc -> smuga")
	assert_almost_eq(p["particle_scale"], 0.75, 0.001, "najwieksza piana przy pelnej predkosci")
	var half := WakeTrail.wake_params(100.0, 200.0, 25.0, 0.35, 0.75)
	assert_almost_eq(half["ratio"], 0.5, 0.001, "polowa predkosci -> ratio 0.5")
	var over := WakeTrail.wake_params(400.0, 200.0, 25.0, 0.35, 0.75)
	assert_almost_eq(over["ratio"], 1.0, 0.001, "powyzej referencji przyciete do 1")

# --- Odstep stempli: rowny w swiecie, rzadszy w scisku ---

func test_stamp_spacing_crowding() -> void:
	assert_almost_eq(WakeTrail.stamp_spacing(9.0, 0.0, 2.2), 9.0, 0.001, "solo -> bazowy odstep")
	assert_almost_eq(WakeTrail.stamp_spacing(9.0, 1.0, 2.2), 19.8, 0.001,
		"pelen scisk -> odstep x2.2 (stado nie muruje sciany piany)")
	assert_almost_eq(WakeTrail.stamp_spacing(9.0, 0.5, 2.2), 14.4, 0.001, "posrednio liniowo")

# --- Geometria "V": burty i dryf na zewnatrz (bez zmian po przebudowie) ---

func test_side_offsets_perpendicular_and_mirrored() -> void:
	var offs := WakeTrail.side_offsets(Vector2(100, 0), 16.0)
	assert_eq(offs.size(), 2, "dwa slady - lewa i prawa burta")
	assert_almost_eq(offs[0].distance_to(Vector2(0, -16)), 0.0, 0.001, "lewa burta prostopadle do ruchu")
	assert_eq(offs[0], -offs[1], "burty symetryczne wzgledem osi ruchu")
	assert_eq(WakeTrail.side_offsets(Vector2.ZERO, 16.0)[0], Vector2.ZERO, "postoj -> brak przesuniecia")

func test_spread_velocity_outward_constant_angle() -> void:
	var v := Vector2(200, 0)
	var left := WakeTrail.spread_velocity(v, -1.0, 0.3)
	assert_almost_eq(left.length(), 60.0, 0.001, "dryf = predkosc * wspolczynnik -> staly kat V")
	assert_eq(left, -WakeTrail.spread_velocity(v, 1.0, 0.3), "dryf lustrzany na obie burty")

func test_width_boost_scales_with_body() -> void:
	assert_almost_eq(WakeTrail.width_boost(16.0, 16.0, 1.5), 1.0, 0.001, "lodz gracza: bez powiekszenia")
	assert_almost_eq(WakeTrail.width_boost(40.0, 16.0, 1.5), 1.5, 0.001,
		"boss: piana umiarkowanie wieksza (cap 1.5 - bez zlanej sciany)")
	assert_almost_eq(WakeTrail.width_boost(40.0, 16.0, 2.0), 2.0, 0.001,
		"boss: odstep stempli x2 (WAKE_WIDTH_SPACING_MAX) - dwie czytelne linie")

# --- Wlasciciele kilwatera: tylko LODZIE pienia wode (gracz + motorowka bossa) ---

func test_fish_have_no_wake_boss_has() -> void:
	var fish = preload("res://scenes/enemies/enemy.tscn").instantiate()
	add_child_autofree(fish)
	var boss = preload("res://scenes/enemies/motor_boat.tscn").instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	var fish_wakes: Array = fish.get_children().filter(func(c): return c is WakeTrail)
	var boss_wakes: Array = boss.get_children().filter(func(c): return c is WakeTrail)
	assert_eq(fish_wakes.size(), 0, "ryba NIE zostawia piany (decyzja wizualno-wydajnosciowa)")
	assert_eq(boss_wakes.size(), 1, "motorowka bossa to lodz - zostawia kilwater jak gracz")

func test_body_half_width_from_shapes_and_fallback() -> void:
	var body := CharacterBody2D.new()
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	cs.shape = circle
	body.add_child(cs)
	assert_almost_eq(WakeTrail.body_half_width(body), 20.0, 0.001, "kolo -> promien")
	body.free()
	var bare := CharacterBody2D.new()
	assert_almost_eq(WakeTrail.body_half_width(bare), GameConfig.WAKE_WIDTH_FALLBACK / 2.0, 0.001,
		"brak kolizji -> fallback")
	bare.free()

# --- WakeField: ring buffer i zanikanie ---

func test_wake_field_pure_helpers() -> void:
	assert_eq(WakeField.wrap_index(799, 800), 799, "w zakresie bez zmian")
	assert_eq(WakeField.wrap_index(800, 800), 0, "koniec bufora zawija na poczatek")
	assert_eq(WakeField.wrap_index(5, 0), 0, "zerowy rozmiar bez dzielenia przez zero")
	assert_almost_eq(WakeField.fade_alpha(0.0, 0.55), 0.55, 0.001, "swiezy stempel pelne krycie")
	assert_almost_eq(WakeField.fade_alpha(1.0, 0.55), 0.0, 0.001, "koniec zycia -> zanik")

func test_wake_field_visible_radius() -> void:
	assert_almost_eq(WakeField.visible_radius(Vector2(1152, 648), 1.0, 64.0), 640.0, 0.001,
		"polowa dluzszego boku + margines (desktop)")
	assert_almost_eq(WakeField.visible_radius(Vector2(1152, 648), 0.85, 64.0), 741.65, 0.1,
		"oddalona kamera mobile widzi wiecej - promien cullingu rosnie")
	assert_true(WakeField.visible_radius(Vector2(1152, 648), 0.0, 64.0) > 0.0,
		"zerowy zoom bez dzielenia przez zero")

func test_wake_field_hard_cap_wraps() -> void:
	var field := WakeField.new()
	add_child_autofree(field)
	await wait_physics_frames(1)
	var cap: int = GameConfig.WAKE_MAX_STAMPS
	for i in cap + 50:
		field.deposit(Vector2(i, 0), Vector2.ZERO, 1.0)
	assert_eq(field._head, 50, "ring buffer zawinal sie po przekroczeniu limitu (twardy sufit)")

# --- Integracja: rowna linia stempli za poruszajaca sie jednostka ---

func test_moving_body_leaves_evenly_spaced_line() -> void:
	var field := WakeField.new()
	add_child_autofree(field)
	var body := CharacterBody2D.new()
	var wake := WakeTrail.attach_to(body, 200.0)
	add_child_autofree(body)
	await wait_physics_frames(1)
	# Deterministycznie: recznie tickujemy zrodlo kilwatera w rytmie 60 Hz, przesuwajac
	# cialo zgodnie z velocity (barakuda-tempo 160 px/s) - zero zaleznosci od schedulera.
	wake.set_physics_process(false)
	body.velocity = Vector2(160, 0)
	var delta := 1.0 / 60.0
	for i in 40:
		body.global_position += body.velocity * delta
		wake._physics_process(delta)
	var xs: Array[float] = []
	for i in field._born_ms.size():
		if field._born_ms[i] >= 0 and field._pos[i].y < 0.0: # lewa burta
			xs.append(field._pos[i].x)
	xs.sort()
	assert_gt(xs.size(), 5, "ruch zostawia serie stempli (nie pojedyncze kropki)")
	for i in range(1, xs.size()):
		var gap: float = xs[i] - xs[i - 1]
		assert_almost_eq(gap, GameConfig.WAKE_SPACING_PX, 0.5,
			"odstep stempli DOKLADNIE staly (linia, nie kropki) - gap %f" % gap)

func test_attach_without_field_is_safe() -> void:
	var body := CharacterBody2D.new()
	WakeTrail.attach_to(body, 200.0)
	add_child_autofree(body)
	body.velocity = Vector2(200, 0)
	await wait_physics_frames(3)
	assert_true(is_instance_valid(body), "brak WakeField w scenie (testy jednostkowe) -> zero crashy")