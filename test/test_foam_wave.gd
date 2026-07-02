extends GutTest

# Spienione fale ambientowe (FoamWave): luk piany "widziany od gory" - pojawia sie,
# przesuwa po wodzie i zanika. Czysta geometria luku + zachowanie wezla + spawner.

func after_each() -> void:
	GameState.reset()

# --- Czysta funkcja arc_points (geometria luku) ---

func test_arc_points_count_and_radius() -> void:
	var pts := FoamWave.arc_points(100.0, deg_to_rad(110.0), 24)
	assert_eq(pts.size(), 24, "tyle punktow emisji, ile zamowiono")
	for p in pts:
		assert_almost_eq(p.length(), 100.0, 0.01, "kazdy punkt luku w odleglosci promienia")

func test_arc_points_symmetric_and_bulge_forward() -> void:
	# Luk wybrzusza sie w strone ruchu (lokalny +X); symetryczny wzgledem osi X.
	var pts := FoamWave.arc_points(100.0, deg_to_rad(110.0), 25)
	var mid := pts[12]
	assert_almost_eq(mid.y, 0.0, 0.5, "srodek luku na osi ruchu")
	assert_almost_eq(mid.x, 100.0, 0.5, "wybrzuszenie do przodu (lokalny +X)")
	assert_almost_eq(pts[0].y, -pts[24].y, 0.5, "konce luku symetryczne")
	assert_true(absf(pts[0].y) > 50.0, "rozpietosc luku wyraznie szersza niz punkt")

func test_arc_points_degenerate_safe() -> void:
	assert_eq(FoamWave.arc_points(100.0, 1.0, 1).size(), 1, "jeden punkt bez dzielenia przez zero")
	assert_eq(FoamWave.arc_points(100.0, 1.0, 0).size(), 0, "zero punktow -> pusta lista")

# --- Czysta funkcja next_interval (odstepy miedzy falami) ---

func test_next_interval_within_bounds() -> void:
	assert_almost_eq(FoamWave.next_interval(0.0, 9.0, 20.0), 9.0, 0.001, "rng 0 -> minimum")
	assert_almost_eq(FoamWave.next_interval(1.0, 9.0, 20.0), 20.0, 0.001, "rng 1 -> maksimum")
	assert_almost_eq(FoamWave.next_interval(0.5, 9.0, 20.0), 14.5, 0.001, "rng 0.5 -> srodek")

# --- Wezel fali: plynie, po czasie gasi emisje i znika sam ---

func test_wave_moves_and_expires() -> void:
	var wave := FoamWave.make(Vector2.ZERO, Vector2.RIGHT, 60.0, 100.0, 0.3)
	add_child_autofree(wave)
	await wait_physics_frames(2)
	assert_true(wave.emitting, "swieza fala emituje piane")
	var x0: float = wave.position.x
	await wait_physics_frames(10)
	assert_gt(wave.position.x, x0 + 1.0, "fala przesuwa sie w kierunku ruchu")
	# travel_time = 0.3 s minal -> front gasnie (wezel zniknie sam po dogasnieciu ogona).
	await wait_seconds(0.5)
	assert_false(wave.emitting, "po czasie zycia frontu emisja gasnie (fala zanika)")

func test_spawner_creates_wave() -> void:
	var spawner := FoamWaveSpawner.new()
	add_child_autofree(spawner)
	var wave := spawner.spawn_wave_at(Vector2(100, 100))
	assert_not_null(wave, "spawner tworzy fale")
	assert_true(is_instance_valid(wave) and wave is FoamWave, "fala to FoamWave")
	assert_true(wave.get_parent() == spawner, "fala podpieta pod spawner (sprzata sie z nim)")
