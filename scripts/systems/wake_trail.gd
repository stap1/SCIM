class_name WakeTrail
extends CPUParticles2D

# Subtelny kilwater za poruszajaca sie jednostka (lodz gracza i wrogowie).
# CPUParticles2D (ograniczenie webowe), local_coords = false: czastki zostaja
# w SWIECIE tam, gdzie jednostka byla - smuga ciagnie sie za kierunkiem plyniecia.
# Dlugosc sladu = predkosc * stale zycie czastki, wiec jest dokladnie o tyle
# dluzszy, o ile szybsza jednostka; dodatkowo rozmiar piany rosnie z predkoscia.
# Czysta funkcja wake_params - testowalna bez drzewa scen.

# Predkosc "pelnej smugi" jednostki (gracz: max_speed; wrog: jego speed).
var reference_speed: float = GameConfig.PLAYER_MAX_SPEED

# Fabryka: tworzy, konfiguruje i podpina kilwater pod cialo (lodz/wrog).
static func attach_to(body: CharacterBody2D, amount_particles: int, ref_speed: float) -> WakeTrail:
	var wake := WakeTrail.new()
	wake.reference_speed = maxf(ref_speed, 1.0)
	wake.amount = amount_particles
	body.add_child(wake)
	return wake

func _ready() -> void:
	local_coords = false          # smuga ZOSTAJE za jednostka
	show_behind_parent = true     # piana pod sprite'em, nie na nim
	emitting = false
	lifetime = GameConfig.WAKE_LIFETIME
	explosiveness = 0.0
	spread = 16.0
	gravity = Vector2.ZERO
	initial_velocity_min = GameConfig.WAKE_DRIFT_SPEED * 0.6
	initial_velocity_max = GameConfig.WAKE_DRIFT_SPEED
	emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 3.0
	scale_amount_min = GameConfig.WAKE_SCALE_SLOW * 0.7
	scale_amount_max = GameConfig.WAKE_SCALE_SLOW
	color = Color(1.0, 1.0, 1.0, 0.28)
	# Piana rozplywa sie do zera - koniec smugi miekko znika.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.8))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	color_ramp = ramp

func _physics_process(_delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	if body == null or GameState.is_game_over:
		emitting = false
		return
	var speed := body.velocity.length()
	var p := wake_params(speed, reference_speed, GameConfig.WAKE_MIN_SPEED,
		GameConfig.WAKE_SCALE_SLOW, GameConfig.WAKE_SCALE_FAST)
	emitting = p["emitting"]
	if not p["emitting"]:
		return
	# Rozmiar piany i lekki dryf "za rufa" - parametry per-emisja (bezpieczne w locie).
	var s: float = p["particle_scale"]
	scale_amount_min = s * 0.7
	scale_amount_max = s
	# direction jest w przestrzeni lokalnej emitera - zdejmij globalna rotacje rodzica.
	direction = (-body.velocity.normalized()).rotated(-global_rotation)

# Czysta funkcja: parametry smugi dla danej predkosci. Ponizej progu brak emisji;
# ratio = predkosc wzgledem referencyjnej (przyciete do 1); rozmiar piany liniowo
# miedzy scale_slow a scale_fast.
static func wake_params(speed: float, reference_speed_value: float, min_speed: float,
		scale_slow: float, scale_fast: float) -> Dictionary:
	var ratio := clampf(speed / maxf(reference_speed_value, 0.001), 0.0, 1.0)
	return {
		"emitting": speed >= min_speed,
		"ratio": ratio,
		"particle_scale": lerpf(scale_slow, scale_fast, ratio),
	}
