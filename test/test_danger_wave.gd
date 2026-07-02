extends GutTest

# Fala przeciwnosci (DangerWave): prad z fala przyspiesza, pod fale delikatnie
# zwalnia; pas dzialania wokol luku; wspolny kierunek wszystkich zywych fal;
# start wraz z rekinami (tier 2 krzywej spawnu); kwestia Santiago raz na sesje.

const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")

func after_each() -> void:
	GameState.reset()

# --- Czysta funkcja current_multiplier (prad) ---

func test_current_with_wave_boosts() -> void:
	var m := DangerWave.current_multiplier(Vector2.RIGHT, Vector2.RIGHT, 0.20, 0.25)
	assert_almost_eq(m, 1.20, 0.001, "plyniecie Z fala -> +20% (ulatwienie)")

func test_current_against_wave_slows() -> void:
	var m := DangerWave.current_multiplier(Vector2.LEFT, Vector2.RIGHT, 0.20, 0.25)
	assert_almost_eq(m, 0.75, 0.001, "plyniecie POD fale -> -25% (delikatne utrudnienie)")

func test_current_perpendicular_neutral() -> void:
	var m := DangerWave.current_multiplier(Vector2.UP, Vector2.RIGHT, 0.20, 0.25)
	assert_almost_eq(m, 1.0, 0.001, "prostopadle do fali -> neutralnie (latwa do uniknieci)")

func test_current_zero_dirs_safe() -> void:
	assert_almost_eq(DangerWave.current_multiplier(Vector2.ZERO, Vector2.RIGHT, 0.2, 0.25), 1.0, 0.001,
		"postoj -> neutralnie")
	assert_almost_eq(DangerWave.current_multiplier(Vector2.RIGHT, Vector2.ZERO, 0.2, 0.25), 1.0, 0.001,
		"fala bez kierunku -> neutralnie")

# --- Czysta funkcja arc_band_contains (pas dzialania) ---

func test_band_contains_on_arc() -> void:
	assert_true(DangerWave.arc_band_contains(Vector2(150, 0), 150.0, deg_to_rad(110.0), 28.0),
		"punkt na luku (srodek rozpietosci) w pasie")
	assert_true(DangerWave.arc_band_contains(Vector2(150 + 20, 0), 150.0, deg_to_rad(110.0), 28.0),
		"punkt w obrebie grubosci pasa")

func test_band_rejects_outside() -> void:
	assert_false(DangerWave.arc_band_contains(Vector2(150 + 40, 0), 150.0, deg_to_rad(110.0), 28.0),
		"za daleko promieniowo -> poza pasem")
	assert_false(DangerWave.arc_band_contains(Vector2.ZERO, 150.0, deg_to_rad(110.0), 28.0),
		"srodek fali -> poza pasem")
	assert_false(DangerWave.arc_band_contains(Vector2(-150, 0), 150.0, deg_to_rad(110.0), 28.0),
		"za lukiem (poza rozpietoscia katowa) -> poza pasem")

# --- Kierunek: jedno zrodlo, latwe do podmiany w przyszlosci ---

func test_roll_direction_unit_and_deterministic() -> void:
	assert_almost_eq(DangerWave.roll_direction(0.37).length(), 1.0, 0.001, "kierunek znormalizowany")
	assert_almost_eq(DangerWave.roll_direction(0.0).distance_to(Vector2.RIGHT), 0.0, 0.001, "rng 0 -> RIGHT")
	assert_almost_eq(DangerWave.roll_direction(0.25).distance_to(Vector2.DOWN), 0.0, 0.001, "rng 0.25 -> 90 stopni")

# --- Bramka czasu: fale wchodza wraz z rekinami ---

func test_can_spawn_gate() -> void:
	assert_false(DangerWaveSpawner.can_spawn(119.9, GameConfig.DANGER_WAVE_START_TIME), "przed rekinami brak fal")
	assert_true(DangerWaveSpawner.can_spawn(120.0, GameConfig.DANGER_WAVE_START_TIME), "od progu fale aktywne")

func test_start_time_matches_shark_tier() -> void:
	# Straznik zgodnosci: DANGER_WAVE_START_TIME musi wskazywac tier, w ktorym plywaja
	# rekiny (fale "pojawiaja sie po rekinach").
	var s = SpawnerScript.new()
	var keys: Array[int] = []
	for k in s.difficulty_curve:
		keys.append(int(k))
	var tier: int = SpawnerScript.current_tier(GameConfig.DANGER_WAVE_START_TIME, keys)
	var scenes: Array = s.difficulty_curve[tier]["enemies"]
	var has_shark := false
	for sc in scenes:
		if (sc as PackedScene).resource_path.contains("shark"):
			has_shark = true
	s.free()
	assert_true(has_shark, "od DANGER_WAVE_START_TIME w krzywej spawnu sa juz rekiny")

# --- Scena: pas dzialania, wspolny kierunek, komunikat raz ---

func test_covers_point_in_world() -> void:
	var wave := DangerWave.make_danger(Vector2.ZERO, Vector2.RIGHT, 70.0, 150.0, 5.0)
	add_child_autofree(wave)
	await wait_physics_frames(1)
	assert_true(wave.covers_point(wave.position + Vector2(150, 0)), "punkt na luku objety pradem")
	assert_false(wave.covers_point(wave.position), "srodek fali nieobjety")

func test_spawned_waves_share_direction() -> void:
	var spawner := DangerWaveSpawner.new()
	add_child_autofree(spawner)
	var w1 := spawner.spawn_wave()
	var w2 := spawner.spawn_wave()
	assert_almost_eq(w1.move_dir().distance_to(w2.move_dir()), 0.0, 0.001,
		"REGULA: zywe fale nigdy nie maja roznych kierunkow naraz")

func test_announce_only_once_per_session() -> void:
	var spawner := DangerWaveSpawner.new()
	add_child_autofree(spawner)
	assert_true(spawner._announce(), "pierwsza fala -> kwestia Santiago o trudach morza")
	assert_false(spawner._announce(), "kolejne fale bez powtarzania komunikatu")

func test_boat_slowed_against_wave_current() -> void:
	# Integracja z lodzia: fala pokrywa lodz, ruch pod fale daje mnoznik < 1, z fala > 1.
	var boat = preload("res://scenes/player/boat.tscn").instantiate()
	add_child_autofree(boat)
	var wave := DangerWave.make_danger(boat.global_position - Vector2(150, 0), Vector2.RIGHT, 70.0, 150.0, 5.0)
	add_child_autofree(wave)
	await wait_physics_frames(1)
	assert_true(wave.covers_point(boat.global_position), "lodz w pasie fali (setup testu)")
	assert_almost_eq(boat._water_current_multiplier(Vector2.LEFT), 1.0 - GameConfig.DANGER_WAVE_SLOW_AGAINST,
		0.001, "pod fale -> spowolnienie")
	assert_almost_eq(boat._water_current_multiplier(Vector2.RIGHT), 1.0 + GameConfig.DANGER_WAVE_BOOST_WITH,
		0.001, "z fala -> przyspieszenie")
	get_tree().paused = false