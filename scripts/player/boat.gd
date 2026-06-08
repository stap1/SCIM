extends CharacterBody2D

@export var max_speed: float = 220.0
@export var acceleration: float = 600.0
@export var friction: float = 700.0
@export var rotation_speed: float = 5.0

# --- NOWE ZMIENNE DLA ZDROWIA ---
@export var max_hp: float = 100.0
var current_hp: float

# --- ZMIENNA DO ANIMACJI FAL (JUICE) ---
var wave_time: float = 0.0

var harpoon_scene = preload("res://scenes/weapons/harpoon.tscn")

# --- ZMIENNE DO PULI HARPUNÓW ---
var harpoon_pool: Array = []
const POOL_SIZE: int = 20

@onready var weapon_timer: Timer = $WeaponTimer
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

# Szukamy paska zdrowia w scenie głównej
@onready var health_bar: ProgressBar = get_parent().get_node_or_null("HealthBar")

func _ready() -> void:
	add_to_group("player")
	
	current_hp = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	
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

func _handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
		
	input_dir = input_dir.normalized()
	
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func take_damage(amount: float) -> void:
	current_hp -= amount
	
	if health_bar:
		health_bar.value = current_hp
		
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)
	
	if current_hp <= 0:
		die()

func die() -> void:
	GameState.trigger_game_over()
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
