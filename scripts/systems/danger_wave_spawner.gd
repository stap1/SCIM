class_name DangerWaveSpawner
extends Node

# Spawner fal przeciwnosci (DangerWave). Wchodzi wraz z rekinami (tier 2 krzywej
# spawnu = GameConfig.DANGER_WAVE_START_TIME; straznik zgodnosci w testach).
# REGULA: wszystkie fale zyjace naraz maja TEN SAM kierunek ruchu - nowa fala
# kopiuje kierunek zywej; nowy kierunek losuje sie dopiero, gdy ekran jest czysty
# (DangerWave.roll_direction = jedyne miejsce generowania, latwe do podmiany).
# Pierwszej fali towarzyszy kwestia Santiago o trudach morza (raz na sesje).

var _timer: float = 0.0
var _announced: bool = false

func _ready() -> void:
	GameState.session_reset.connect(_on_session_reset)
	_reset_timer()

func _on_session_reset() -> void:
	_announced = false
	_reset_timer()

func _reset_timer() -> void:
	_timer = FoamWave.next_interval(randf(),
		GameConfig.DANGER_WAVE_INTERVAL_MIN, GameConfig.DANGER_WAVE_INTERVAL_MAX)

func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		return
	if not can_spawn(GameState.time, GameConfig.DANGER_WAVE_START_TIME):
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_reset_timer()
	spawn_wave()

# Czysta funkcja: fale przeciwnosci dopiero od czasu wejscia rekinow.
static func can_spawn(time_s: float, start_s: float) -> bool:
	return time_s >= start_s

# Kierunek zywych fal (regula wspolnego kierunku) albo ZERO gdy ekran czysty.
func active_direction() -> Vector2:
	for c in get_children():
		if c is DangerWave and is_instance_valid(c):
			return (c as DangerWave).move_dir()
	return Vector2.ZERO

# Tworzy fale przecinajaca widok gracza. Publiczne - testy wolaja bezposrednio.
func spawn_wave() -> DangerWave:
	var dir := active_direction()
	if dir == Vector2.ZERO:
		dir = DangerWave.roll_direction(randf())
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var center := player.global_position if player != null else Vector2.ZERO
	var radius := randf_range(GameConfig.DANGER_WAVE_RADIUS_MIN, GameConfig.DANGER_WAVE_RADIUS_MAX)
	# Start za krawedzia kadru po stronie przeciwnej do kierunku - fala przeplywa
	# przez ekran i znika po drugiej stronie (czas podrozy z geometrii, nie na sztywno).
	var extent := _visible_extent() * 0.5 + radius
	var lateral := dir.orthogonal() * randf_range(-0.3, 0.3) * _visible_extent()
	var travel_time := (extent * 2.0) / maxf(GameConfig.DANGER_WAVE_SPEED, 1.0)
	var wave := DangerWave.make_danger(center - dir * extent + lateral, dir,
		GameConfig.DANGER_WAVE_SPEED, radius, travel_time)
	add_child(wave)
	_announce()
	return wave

# Widoczny obszar swiata (dluzszy bok kadru, z korekta zoomu kamery).
func _visible_extent() -> float:
	var vp := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.zoom.x > 0.0 and cam.zoom.y > 0.0:
		vp /= cam.zoom
	return maxf(vp.x, vp.y)

# Kwestia Santiago o trudach morza - dokladnie raz na sesje, przy pierwszej fali.
# Zwraca true, gdy komunikat faktycznie poszedl (testowalny guard).
func _announce() -> bool:
	if _announced:
		return false
	_announced = true
	var banner := get_tree().get_first_node_in_group("dialogue_banner")
	if banner != null and banner.has_method("enqueue"):
		banner.enqueue(NarrativeData.FIRST_DANGER_WAVE)
	return true
