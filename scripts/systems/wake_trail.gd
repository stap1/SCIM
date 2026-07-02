class_name WakeTrail
extends Node2D

# Kilwater: DWA slady piany rozchodzace sie w "V" za poruszajaca sie jednostka
# (lodz gracza i wrogowie). Dwa CPUParticles2D (ograniczenie webowe) na burtach:
# - rozstaw sladow = szerokosc zrodla (z CollisionShape2D - szersza jednostka,
#   szerszy kilwater),
# - czastki w SWIECIE (local_coords=false) dryfuja NA ZEWNATRZ z predkoscia
#   proporcjonalna do predkosci jednostki -> kat "V" jest staly, a slad rozszerza
#   sie tym mocniej, im szybciej plynie zrodlo,
# - dlugosc sladu = predkosc * stale zycie czastki (scisle proporcjonalna),
#   rozmiar piany rosnie z predkoscia.
# Czyste funkcje (wake_params / side_offsets / spread_velocity) - testowalne bez scen.

# Predkosc "pelnej smugi" jednostki (gracz: max_speed; wrog: jego speed).
var reference_speed: float = GameConfig.PLAYER_MAX_SPEED
# Pol-szerokosci zrodla - rozstaw emiterow na burtach.
var half_width: float = GameConfig.WAKE_WIDTH_FALLBACK / 2.0

var _amount_per_side: int = 6
var _sides: Array[CPUParticles2D] = []

# Fabryka: tworzy, konfiguruje i podpina kilwater pod cialo (lodz/wrog).
# Szerokosc sladu wyprowadzana z kolizji ciala - bez recznych parametrow per typ.
static func attach_to(body: CharacterBody2D, amount_particles: int, ref_speed: float) -> WakeTrail:
	var wake := WakeTrail.new()
	wake.reference_speed = maxf(ref_speed, 1.0)
	wake.half_width = body_half_width(body)
	wake._amount_per_side = maxi(1, amount_particles / 2)
	body.add_child(wake)
	return wake

func _ready() -> void:
	show_behind_parent = true # piana pod sprite'em jednostki
	for i in 2:
		var side := _make_side_emitter()
		add_child(side)
		_sides.append(side)

func _make_side_emitter() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.local_coords = false        # slad ZOSTAJE za jednostka
	p.emitting = false
	p.amount = _amount_per_side
	p.lifetime = GameConfig.WAKE_LIFETIME
	p.explosiveness = 0.0
	p.spread = 6.0                # waska struga - czytelna linia "V"
	p.gravity = Vector2.ZERO
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 2.0
	p.scale_amount_min = GameConfig.WAKE_SCALE_SLOW * 0.7
	p.scale_amount_max = GameConfig.WAKE_SCALE_SLOW
	p.color = Color(1.0, 1.0, 1.0, 0.28)
	# Piana rozplywa sie do zera - koniec sladu miekko znika.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.8))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = ramp
	return p

func _physics_process(_delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if body == null or _sides.size() < 2 or GameState.is_game_over:
		_set_emitting(false)
		return
	var speed := body.velocity.length()
	var p := wake_params(speed, reference_speed, GameConfig.WAKE_MIN_SPEED,
		GameConfig.WAKE_SCALE_SLOW, GameConfig.WAKE_SCALE_FAST)
	if not p["emitting"]:
		_set_emitting(false)
		return
	var offs := side_offsets(body.velocity, half_width)
	var s: float = p["particle_scale"]
	for i in 2:
		var side := _sides[i]
		var sign_dir := -1.0 if i == 0 else 1.0
		var drift := spread_velocity(body.velocity, sign_dir, GameConfig.WAKE_SPREAD_RATIO)
		side.emitting = true
		side.global_position = body.global_position + offs[i]
		# direction jest w przestrzeni lokalnej emitera - zdejmij globalna rotacje.
		side.direction = drift.normalized().rotated(-side.global_rotation)
		side.initial_velocity_min = drift.length() * 0.8
		side.initial_velocity_max = drift.length() * 1.05
		side.scale_amount_min = s * 0.7
		side.scale_amount_max = s

func _set_emitting(on: bool) -> void:
	for side in _sides:
		side.emitting = on

# --- Czyste funkcje (testowalne bez drzewa scen) ---

# Parametry smugi dla danej predkosci: prog emisji, ratio wzgledem referencji
# (przyciete do 1), rozmiar piany liniowo miedzy scale_slow a scale_fast.
static func wake_params(speed: float, reference_speed_value: float, min_speed: float,
		scale_slow: float, scale_fast: float) -> Dictionary:
	var ratio := clampf(speed / maxf(reference_speed_value, 0.001), 0.0, 1.0)
	return {
		"emitting": speed >= min_speed,
		"ratio": ratio,
		"particle_scale": lerpf(scale_slow, scale_fast, ratio),
	}

# Pozycje burt: [lewa, prawa] - przesuniecia prostopadle do kierunku ruchu
# o pol-szerokosci zrodla. Postoj -> [ZERO, ZERO] (bez normalizacji wektora zerowego).
static func side_offsets(velocity: Vector2, half_width_px: float) -> Array[Vector2]:
	if velocity == Vector2.ZERO:
		return [Vector2.ZERO, Vector2.ZERO]
	var perp := Vector2(-velocity.y, velocity.x).normalized()
	return [-perp * half_width_px, perp * half_width_px]

# Dryf piany na zewnatrz (prostopadle do ruchu, w strone burty side_sign).
# Predkosc dryfu ~ predkosc jednostki -> kat rozejscia "V" staly niezaleznie od tempa.
static func spread_velocity(velocity: Vector2, side_sign: float, spread_ratio: float) -> Vector2:
	if velocity == Vector2.ZERO:
		return Vector2.ZERO
	var perp := Vector2(-velocity.y, velocity.x).normalized()
	return perp * side_sign * velocity.length() * spread_ratio

# Pol-szerokosc ciala z pierwszego CollisionShape2D (kolo -> promien, prostokat ->
# polowa X, kapsula -> promien). Brak kolizji -> fallback z GameConfig.
static func body_half_width(body: CharacterBody2D) -> float:
	for child in body.get_children():
		var cs := child as CollisionShape2D
		if cs == null or cs.shape == null:
			continue
		var shape := cs.shape
		if shape is CircleShape2D:
			return (shape as CircleShape2D).radius
		if shape is RectangleShape2D:
			return (shape as RectangleShape2D).size.x / 2.0
		if shape is CapsuleShape2D:
			return (shape as CapsuleShape2D).radius
	return GameConfig.WAKE_WIDTH_FALLBACK / 2.0
