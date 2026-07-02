extends CharacterBody2D

# Wartosci startowe z GameConfig (jedyne zrodlo balansu); @export pozwala na tweak w scenie.
@export var max_speed: float = GameConfig.PLAYER_MAX_SPEED
@export var acceleration: float = GameConfig.PLAYER_ACCELERATION
@export var friction: float = GameConfig.PLAYER_FRICTION
@export var rotation_speed: float = GameConfig.PLAYER_ROTATION_SPEED

# --- Obrazenia od kontaktu z wrogiem ---
# Zasada: HP gracza zyje WYLACZNIE w GameState. Lodz tylko wykrywa kontakt i czyta
# obrazenia z trafionego wroga (per-wrog contact_damage). damage_per_hit to fallback.
@export var damage_per_hit: float = GameConfig.PLAYER_CONTACT_DAMAGE
@export var hit_cooldown: float = GameConfig.PLAYER_HIT_COOLDOWN
var time_since_last_hit: float = 999.0

# --- ZMIENNA DO ANIMACJI FAL (JUICE) ---
var wave_time: float = 0.0

# --- Sterowanie (modul wyboru trybu): cel podrozy (klik/dotyk) + kalibracja akcelerometru ---
var _travel_target: Vector2 = Vector2.ZERO
var _has_travel_target: bool = false
var _accel_zero: Vector2 = Vector2.ZERO
var _accel_calibrated: bool = false

@onready var hurtbox: Area2D = $Hurtbox
@onready var camera: Camera2D = get_node_or_null("Camera2D")

func _ready() -> void:
	add_to_group("player")

	# HP gracza zyje w GameState (jedyne zrodlo prawdy). Reset na starcie sceny (takze po restarcie).
	# Pasek zycia pokazuje HUD (read-only przez sygnal health_changed) - lodz go nie dotyka.
	GameState.health = GameState.max_health
	GameState.health_changed.connect(_on_health_changed)

	# Build pionowy: kamera lekko oddalona - podobny obszar gry co na desktopie.
	if camera:
		camera.zoom = Vector2.ONE * Platform.camera_zoom(Platform.is_mobile_build())
	# Zmiana trybu sterowania w locie (pauza/ustawienia): czysc cel i kalibracje.
	SettingsStore.control_mode_changed.connect(_on_control_mode_changed)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	move_and_slide()

	if velocity.length() > 10:
		var target_angle = velocity.angle() + PI/2
		rotation = rotate_toward(rotation, target_angle, rotation_speed * delta)

	# Kontakt z wrogiem - JEDNA sciezka: polling Hurtboxa co klatke fizyki (pierwszy cios
	# w obrebie klatki + obrazenia ciagle). Obrazenia WYLACZNIE przez GameState, z cooldownem (i-frames).
	time_since_last_hit += delta
	if not GameState.is_game_over:
		var enemy := _first_enemy_in_hurtbox()
		if enemy:
			try_take_enemy_hit(contact_damage_of(enemy))

# Znormalizowany kierunek wejscia z akcji InputMap (move_*). Akcje pozwalaja na
# remapowanie i sterowanie mobilne (przyciski dotykowe emituja te same akcje).
func get_input_direction() -> Vector2:
	return direction_from_input(
		Input.is_action_pressed("move_right"),
		Input.is_action_pressed("move_left"),
		Input.is_action_pressed("move_down"),
		Input.is_action_pressed("move_up"))

# --- Sterowanie: cele podrozy (klik/dotyk) i kierunek wg wybranego trybu ---

func _unhandled_input(event: InputEvent) -> void:
	var mode: String = SettingsStore.control_mode
	# Click-to-follow: LPM ustawia cel podrozy (klikniecia w UI konsumuje wczesniej GUI).
	if mode == ControlModes.MOUSE_CLICK and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_set_travel_target(get_global_mouse_position())
	# Podazanie za dotykiem: palec = cel (przeciaganie aktualizuje); puszczenie palca
	# NIE kasuje celu - lodz doplywa do ostatniego punktu i staje.
	elif mode == ControlModes.TOUCH_FOLLOW:
		if event is InputEventScreenDrag:
			_set_travel_target(_screen_to_world((event as InputEventScreenDrag).position))
		elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			_set_travel_target(_screen_to_world((event as InputEventScreenTouch).position))

func _set_travel_target(world_pos: Vector2) -> void:
	_travel_target = world_pos
	_has_travel_target = true

# Pozycja ekranowa zdarzenia dotyku -> wspolrzedne swiata (przez transformacje canvasu).
func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos

func _on_control_mode_changed(_mode: String) -> void:
	_has_travel_target = false
	_accel_calibrated = false # ponowna kalibracja przy kazdym wejsciu w tryb akcelerometru

# Kierunek ruchu wg trybu z SettingsStore. Wejscia do czystego routera przekazywane jawnie.
func _movement_direction() -> Vector2:
	var mode: String = SettingsStore.control_mode
	# Akcelerometr (mobile, eksperymentalny): przechyl wzgledem punktu kalibracji.
	if mode == ControlModes.ACCEL:
		return _accel_direction()
	var target := _travel_target
	var has_target := _has_travel_target
	var deadzone := GameConfig.CONTROL_TARGET_DEADZONE_PX
	if mode == ControlModes.MOUSE_FOLLOW:
		target = get_global_mouse_position()
		deadzone = GameConfig.CONTROL_CURSOR_DEADZONE_PX
	var dir := ControlModes.dispatch_direction(mode, get_input_direction(), global_position,
		target, has_target, deadzone, _joystick_vector(), GameConfig.CONTROL_JOYSTICK_DEADZONE)
	# Cel podrozy osiagniety -> wyczysc (lodz stoi do nastepnego klikniecia/dotyku).
	if (mode == ControlModes.MOUSE_CLICK or mode == ControlModes.TOUCH_FOLLOW) \
			and _has_travel_target and dir == Vector2.ZERO:
		_has_travel_target = false
	return dir

# Wektor galki joysticka ekranowego (grupa "touch_joystick" - luzne powiazanie scen).
func _joystick_vector() -> Vector2:
	var joy := get_tree().get_first_node_in_group("touch_joystick")
	if joy != null and "vector" in joy:
		return joy.vector
	return Vector2.ZERO

# Kierunek z akcelerometru: pierwszy odczyt trybu kalibruje zero-point (naturalny chwyt).
# Brak sensora/zgody -> ZERO (lodz stoi; gracz moze zmienic tryb w pauzie).
func _accel_direction() -> Vector2:
	var raw := Input.get_accelerometer()
	if raw == Vector3.ZERO:
		return Vector2.ZERO
	var flat := Vector2(raw.x, raw.y)
	if not _accel_calibrated:
		_accel_zero = flat
		_accel_calibrated = true
		return Vector2.ZERO
	var tilt := ControlModes.tilt_from_accel(flat, _accel_zero)
	return ControlModes.direction_from_accel(tilt,
		GameConfig.CONTROL_ACCEL_DEADZONE, GameConfig.CONTROL_ACCEL_SENSITIVITY)

# Czysta funkcja: kierunek z 4 stanow wcisniecia. Normalizacja gwarantuje, ze ruch
# ukosny nie jest szybszy niz prosty; przeciwne kierunki kasuja sie.
static func direction_from_input(right: bool, left: bool, down: bool, up: bool) -> Vector2:
	var dir := Vector2.ZERO
	if right:
		dir.x += 1
	if left:
		dir.x -= 1
	if down:
		dir.y += 1
	if up:
		dir.y -= 1
	return dir.normalized()

# Czysta funkcja bez zaleznosci od drzewa scen: docelowa predkosc dla danego kierunku.
# Normalizacja gwarantuje, ze ruch ukosny nie jest szybszy niz prosty.
static func compute_velocity(direction: Vector2, speed: float) -> Vector2:
	return direction.normalized() * speed

func _handle_movement(delta: float) -> void:
	var input_dir := _movement_direction()
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

# Czysta funkcja: czy minelo dosc czasu od ostatniego trafienia (i-frames).
static func can_take_hit(time_since_last: float, cooldown: float) -> bool:
	return time_since_last >= cooldown

# Pierwszy wrog nakladajacy sie na Hurtbox (lub null) - zrodlo obrazen kontaktowych.
func _first_enemy_in_hurtbox() -> Node:
	if hurtbox == null:
		return null
	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			return body
	return null

# Obrazenia kontaktowe danego wroga (per-wrog). Fallback na damage_per_hit, gdy
# zrodlo nie niesie wlasnej wartosci (defensywnie - kazdy wrog z EnemyBase ja ma).
func contact_damage_of(enemy: Node) -> float:
	if enemy and "contact_damage" in enemy:
		return enemy.contact_damage
	return damage_per_hit

# Logika trafienia gracza przez wroga - obrazenia (per-wrog) tylko przez GameState, z cooldownem.
func try_take_enemy_hit(damage: float) -> void:
	if not can_take_hit(time_since_last_hit, hit_cooldown):
		return
	GameState.take_damage(damage)
	time_since_last_hit = 0.0
	AudioManager.play_sfx("player_hit")
	if is_inside_tree():
		_flash_hit()
		_do_shake()

# Trzesienie ekranu na trafieniu - pomijane gdy accessibility "reduce shake" wlaczone.
func _do_shake() -> void:
	if camera == null:
		return
	if not SettingsStore.should_apply_shake(SettingsStore.reduce_shake):
		return
	var t := create_tween()
	camera.offset = Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
	t.tween_property(camera, "offset", Vector2.ZERO, 0.2)

func _flash_hit() -> void:
	modulate = Color(1, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.15)

func _on_health_changed(new_health: float) -> void:
	if new_health <= 0.0:
		die()

func die() -> void:
	# Game over wyzwala GameState.take_damage przy HP<=0. Tu animacja smierci lodzi.
	set_physics_process(false)
	# ALWAYS, by animacja zagrala mimo get_tree().paused (ekran game over).
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.5)
	tween.tween_property(self, "rotation", rotation + PI, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

# Dzwiek strzalu - publiczne API dla AutoAttacker (SFX centralnie przez AudioManager).
func play_shoot_sound() -> void:
	AudioManager.play_sfx("harpoon_shot")

# --- ODŚWIEŻANIE WIZUALNE (juice fal). Licznik amunicji jest event-driven w HUD. ---
func _process(delta: float) -> void:
	if GameState.is_game_over:
		return

	wave_time += delta

	if has_node("Sprite2D"):
		$Sprite2D.position.y = sin(wave_time * 4.0) * 3.0
		$Sprite2D.rotation = cos(wave_time * 2.5) * 0.05
