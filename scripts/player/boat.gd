extends CharacterBody2D

@export var max_speed: float = 200.0
@export var acceleration: float = 600.0
@export var friction: float = 700.0
@export var rotation_speed: float = 5.0

# --- Obrazenia od kontaktu z wrogiem ---
# Zasada: HP gracza zyje WYLACZNIE w GameState. Lodz tylko wykrywa kontakt.
@export var damage_per_hit: float = 10.0
@export var hit_cooldown: float = 0.5
var time_since_last_hit: float = 999.0

# --- ZMIENNA DO ANIMACJI FAL (JUICE) ---
var wave_time: float = 0.0

var harpoon_scene = preload("res://scenes/weapons/harpoon.tscn")

# --- ZMIENNE DO PULI HARPUNÓW ---
var harpoon_pool: Array = []
const POOL_SIZE: int = 20

@onready var weapon_timer: Timer = $WeaponTimer
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	add_to_group("player")

	# HP gracza zyje w GameState (jedyne zrodlo prawdy). Reset na starcie sceny (takze po restarcie).
	# Pasek zycia pokazuje HUD (read-only przez sygnal health_changed) - lodz go nie dotyka.
	GameState.health = GameState.max_health
	GameState.health_changed.connect(_on_health_changed)

	# Hurtbox wykrywa wrogow: sygnal daje natychmiastowy pierwszy cios,
	# a polling w _physics_process zapewnia obrazenia ciagle (oba bramkowane cooldownem).
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)

	if weapon_timer:
		if weapon_timer.timeout.is_connected(_on_weapon_timer_timeout):
			weapon_timer.timeout.disconnect(_on_weapon_timer_timeout)
		weapon_timer.timeout.connect(_on_weapon_timer_timeout)

	# --- TWORZENIE PULI HARPUNÓW ---
	for i in range(POOL_SIZE):
		var harpoon = harpoon_scene.instantiate()
		get_parent().call_deferred("add_child", harpoon)
		harpoon_pool.append(harpoon)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	move_and_slide()

	if velocity.length() > 10:
		var target_angle = velocity.angle() + PI/2
		rotation = rotate_toward(rotation, target_angle, rotation_speed * delta)

	# Kontakt z wrogiem: Hurtbox wykrywa, obrazenia ida WYLACZNIE przez GameState, z cooldownem (i-frames).
	time_since_last_hit += delta
	if not GameState.is_game_over and _enemy_in_hurtbox():
		try_take_enemy_hit()

# Znormalizowany kierunek wejscia (WSAD + strzalki). Wydzielone dla testowalnosci.
func get_input_direction() -> Vector2:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	return input_dir.normalized()

# Czysta funkcja bez zaleznosci od drzewa scen: docelowa predkosc dla danego kierunku.
# Normalizacja gwarantuje, ze ruch ukosny nie jest szybszy niz prosty.
static func compute_velocity(direction: Vector2, speed: float) -> Vector2:
	return direction.normalized() * speed

func _handle_movement(delta: float) -> void:
	var input_dir := get_input_direction()
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

# Czysta funkcja: czy minelo dosc czasu od ostatniego trafienia (i-frames).
static func can_take_hit(time_since_last: float, cooldown: float) -> bool:
	return time_since_last >= cooldown

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not GameState.is_game_over and body.is_in_group("enemies"):
		try_take_enemy_hit()

func _enemy_in_hurtbox() -> bool:
	if hurtbox == null:
		return false
	for body in hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			return true
	return false

# Logika trafienia gracza przez wroga - obrazenia tylko przez GameState, z cooldownem.
func try_take_enemy_hit() -> void:
	if not can_take_hit(time_since_last_hit, hit_cooldown):
		return
	GameState.take_damage(damage_per_hit)
	time_since_last_hit = 0.0
	if is_inside_tree():
		_flash_hit()

func _flash_hit() -> void:
	modulate = Color(1, 0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.15)

func _on_health_changed(new_health: float) -> void:
	if new_health <= 0.0:
		die()

func die() -> void:
	# Game over wyzwala GameState.take_damage przy HP<=0. Tu tylko reakcja wizualna lodzi.
	hide()
	set_physics_process(false)

	if weapon_timer:
		weapon_timer.stop()

func _on_weapon_timer_timeout() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	var closest_enemy = enemies[0]
	var min_distance = global_position.distance_to(closest_enemy.global_position)

	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy

	_shoot_at(closest_enemy.global_position)

func _shoot_at(target_position: Vector2) -> void:
	var available_harpoon = null
	for harpoon in harpoon_pool:
		if not harpoon.is_active:
			available_harpoon = harpoon
			break

	if available_harpoon:
		var shoot_dir = (target_position - global_position).normalized()
		available_harpoon.fire(global_position, shoot_dir)

		if shoot_sound:
			shoot_sound.play()
	else:
		print("Brak wolnych harpunów w puli!")

# --- ODŚWIEŻANIE WIZUALNE I LICZNIK ---
func _process(delta: float) -> void:
	if GameState.is_game_over:
		return

	wave_time += delta

	if has_node("Sprite2D"):
		$Sprite2D.position.y = sin(wave_time * 4.0) * 3.0
		$Sprite2D.rotation = cos(wave_time * 2.5) * 0.05

	# Pancerne aktualizowanie licznika przez Grupy
	var ui_labels = get_tree().get_nodes_in_group("ammo_ui")
	if ui_labels.size() > 0:
		var available_count = 0
		for harpoon in harpoon_pool:
			if not harpoon.is_active:
				available_count += 1

		ui_labels[0].text = str(available_count) + " / " + str(POOL_SIZE)
