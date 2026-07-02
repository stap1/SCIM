class_name WakeTrail
extends Node2D

# Zrodlo kilwatera jednostki: NIE emituje czastek samo - odklada "stemple" piany
# do wspolnego WakeField co WAKE_SPACING_PX PRZEBYTEJ DROGI (dwie burty naraz).
# Odstep liczony z drogi (nie z czasu) daje idealnie rowna linie niezaleznie od
# predkosci i FPS; jeden wspolny rysownik zamiast dwoch CPUParticles2D na jednostke
# usuwa koszt emiterow przy stadzie wrogow. Czyste funkcje na dole - testowalne.

# Predkosc "pelnej smugi" jednostki (gracz: max_speed; wrog: jego speed).
var reference_speed: float = GameConfig.PLAYER_MAX_SPEED
# Pol-szerokosci zrodla - rozstaw sladow na burtach.
var half_width: float = GameConfig.WAKE_WIDTH_FALLBACK / 2.0

var _scale_boost: float = 1.0
var _travel_accum: float = 0.0
var _field: WakeField = null

# Wspolna miekka tekstura piany (radialny gradient generowany w kodzie - bez plikow
# art). Uzywana przez WakeField (stemple) i FoamWave/DangerWave (fale).
static var _foam_texture: Texture2D = null

static func foam_texture() -> Texture2D:
	if _foam_texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = GameConfig.WAKE_TEXTURE_SIZE
		t.height = GameConfig.WAKE_TEXTURE_SIZE
		_foam_texture = t
	return _foam_texture

# Fabryka: tworzy i podpina zrodlo kilwatera pod cialo (lodz/wrog). Szerokosc sladu
# z kolizji ciala - bez recznych parametrow per typ.
static func attach_to(body: CharacterBody2D, ref_speed: float) -> WakeTrail:
	var wake := WakeTrail.new()
	wake.reference_speed = maxf(ref_speed, 1.0)
	wake.half_width = body_half_width(body)
	body.add_child(wake)
	return wake

func _ready() -> void:
	# Kamera na mobile jest oddalona, ekran fizycznie maly - piana odrobine wieksza.
	# Szersze jednostki (boss) dostaja wieksze stemple - szeroki slad nie wyglada rzadko.
	_scale_boost = (GameConfig.WAKE_MOBILE_SCALE_BOOST if Platform.is_mobile_build() else 1.0) \
		* width_boost(half_width, GameConfig.WAKE_WIDTH_REF, GameConfig.WAKE_WIDTH_BOOST_MAX)

func _physics_process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if body == null or GameState.is_game_over:
		return
	var speed := body.velocity.length()
	var p := wake_params(speed, reference_speed, GameConfig.WAKE_MIN_SPEED,
		GameConfig.WAKE_SCALE_SLOW, GameConfig.WAKE_SCALE_FAST)
	if not p["emitting"]:
		_travel_accum = 0.0 # postoj: slad zaczyna sie od nowa
		return
	if _field == null or not is_instance_valid(_field):
		_field = get_tree().get_first_node_in_group("wake_field") as WakeField
		if _field == null:
			return # scena bez pola piany (np. testy jednostkowe lodzi) - brak sladu
	# W scisku (separacja aktywna) stemple rzadsze; szeroka jednostka (boss) tez ma
	# proporcjonalnie rzadsze stemple - wiekszej pianie odpowiada wiekszy odstep,
	# wiec slad czyta sie jako dwie linie, a nie zlana sciana.
	var spacing := stamp_spacing(GameConfig.WAKE_SPACING_PX, _crowding(body),
		GameConfig.WAKE_CROWD_SPACING_MULT) \
		* width_boost(half_width, GameConfig.WAKE_WIDTH_REF, GameConfig.WAKE_WIDTH_SPACING_MAX)
	_travel_accum += speed * delta
	if _travel_accum < spacing:
		return
	var offs := side_offsets(body.velocity, half_width)
	var stamp_scale: float = p["particle_scale"] * _scale_boost
	var dir := body.velocity / maxf(speed, 0.001)
	while _travel_accum >= spacing:
		_travel_accum -= spacing
		# Cofniecie o nadmiar drogi: stemple laduja DOKLADNIE co spacing wzdluz toru.
		var back := dir * _travel_accum
		_field.deposit(body.global_position - back + offs[0],
			spread_velocity(body.velocity, -1.0, GameConfig.WAKE_SPREAD_RATIO), stamp_scale)
		_field.deposit(body.global_position - back + offs[1],
			spread_velocity(body.velocity, 1.0, GameConfig.WAKE_SPREAD_RATIO), stamp_scale)

# Zatloczenie jednostki [0,1] - wrogowie wystawiaja separation_crowding (EnemyBase),
# lodz gracza plywa solo (0).
func _crowding(body: CharacterBody2D) -> float:
	if "separation_crowding" in body:
		return clampf(float(body.get("separation_crowding")), 0.0, 1.0)
	return 0.0

# --- Czyste funkcje (testowalne bez drzewa scen) ---

# Odstep stempli dla danego zatloczenia: w scisku rosnie do base * crowd_mult.
static func stamp_spacing(base_px: float, crowding: float, crowd_mult: float) -> float:
	return base_px * lerpf(1.0, maxf(crowd_mult, 1.0), clampf(crowding, 0.0, 1.0))

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

# Mnoznik rozmiaru piany dla szerokich jednostek (>= 1.0, przyciety od gory).
static func width_boost(half_width_px: float, ref_half_width: float, boost_max: float) -> float:
	return clampf(half_width_px / maxf(ref_half_width, 0.001), 1.0, boost_max)

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
