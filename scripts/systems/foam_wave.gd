class_name FoamWave
extends CPUParticles2D

# Ambientowa spieniona fala: luk piany "widziany od gory" - pojawia sie, przesuwa
# po wodzie i zanika. Piana emitowana wzdluz luku (EMISSION_SHAPE_POINTS), czastki
# zostaja w swiecie (local_coords=false), wiec przesuwajacy sie front zostawia
# gasnacy ogon - jak grzbiet fali. Czysto wizualna (bez kolizji).
# Przyszla ewolucja w feature gry ("niebezpieczne fale"): dolozyc Area2D wzdluz luku.

var _dir: Vector2 = Vector2.RIGHT
var _move_speed: float = 45.0
var _travel_left: float = GameConfig.FOAM_WAVE_TRAVEL_TIME
var _radius: float = GameConfig.FOAM_WAVE_RADIUS_MIN
var _expired: bool = false

# Fabryka: fala w pozycji startowej, plynaca w dir z zadana predkoscia; luk o zadanym
# promieniu wybrzuszony w strone ruchu. travel_time = czas zycia frontu (potem zanik).
static func make(start_pos: Vector2, dir: Vector2, move_speed: float, radius: float,
		travel_time: float) -> FoamWave:
	return FoamWave.new().setup(start_pos, dir, move_speed, radius, travel_time)

# Konfiguracja instancji (uzywana tez przez podklasy, np. DangerWave). Zwraca self.
func setup(start_pos: Vector2, dir: Vector2, move_speed: float, radius: float,
		travel_time: float) -> FoamWave:
	position = start_pos
	_dir = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT
	_move_speed = move_speed
	_travel_left = travel_time
	_radius = radius
	rotation = _dir.angle() # luk (lokalny +X) wybrzuszony w strone ruchu
	_configure(radius)
	return self

# Kierunek ruchu fali (znormalizowany) - czytany przez spawnery (regula wspolnego
# kierunku) i przez lodz (prad DangerWave).
func move_dir() -> Vector2:
	return _dir

func _configure(radius: float) -> void:
	texture = WakeTrail.foam_texture() # ta sama miekka piana co kilwater
	local_coords = false               # ogon fali ZOSTAJE na wodzie
	emitting = true
	amount = GameConfig.FOAM_WAVE_ARC_POINTS * 2
	lifetime = GameConfig.WAKE_LIFETIME * 1.4
	explosiveness = 0.0
	spread = 180.0
	gravity = Vector2.ZERO
	initial_velocity_min = 0.0
	initial_velocity_max = 6.0
	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	emission_points = arc_points(radius, deg_to_rad(GameConfig.FOAM_WAVE_SPAN_DEG),
		GameConfig.FOAM_WAVE_ARC_POINTS)
	scale_amount_min = GameConfig.WAKE_SCALE_FAST * 0.6
	scale_amount_max = GameConfig.WAKE_SCALE_FAST * 1.1
	color = Color(1.0, 1.0, 1.0, GameConfig.FOAM_WAVE_ALPHA)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	color_ramp = ramp

func _physics_process(delta: float) -> void:
	if _expired:
		return
	position += _dir * _move_speed * delta
	_travel_left -= delta
	if _travel_left <= 0.0:
		# Front gasnie; ogon dogasa przez zycie czastek, potem wezel sprzata sie sam.
		_expired = true
		emitting = false
		get_tree().create_timer(lifetime + 0.2).timeout.connect(queue_free)

# --- Czyste funkcje (testowalne bez drzewa scen) ---

# Punkty luku o zadanym promieniu i rozpietosci katowej, symetrycznie wokol
# lokalnej osi +X (kierunek ruchu fali). count <= 0 -> pusta lista.
static func arc_points(radius: float, span_rad: float, count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if count <= 0:
		return pts
	if count == 1:
		pts.append(Vector2(radius, 0.0))
		return pts
	for i in count:
		var t := float(i) / float(count - 1) - 0.5
		pts.append(Vector2(radius, 0.0).rotated(t * span_rad))
	return pts

# Losowy odstep miedzy falami w widelkach (rng_value w [0,1]).
static func next_interval(rng_value: float, min_s: float, max_s: float) -> float:
	return lerpf(min_s, max_s, clampf(rng_value, 0.0, 1.0))
