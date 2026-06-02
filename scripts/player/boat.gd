extends CharacterBody2D

@export var max_speed: float = 220.0
@export var acceleration: float = 600.0
@export var friction: float = 700.0
@export var rotation_speed: float = 5.0

# --- NOWE ZMIENNE DLA ZDROWIA ---
@export var max_hp: float = 100.0
var current_hp: float

var harpoon_scene = preload("res://scenes/weapons/harpoon.tscn")
@onready var weapon_timer: Timer = $WeaponTimer
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

# Szukamy paska zdrowia w scenie głównej (rodzicu łodzi)
@onready var health_bar: ProgressBar = get_parent().get_node("HealthBar")

func _ready() -> void:
	add_to_group("player")
	
	# Ustawiamy HP na maksimum przy starcie
	current_hp = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	
	if weapon_timer:
		if weapon_timer.timeout.is_connected(_on_weapon_timer_timeout):
			weapon_timer.timeout.disconnect(_on_weapon_timer_timeout)
		weapon_timer.timeout.connect(_on_weapon_timer_timeout)

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

# --- OTRZYMYWANIE OBRAŻEŃ ---
func take_damage(amount: float) -> void:
	current_hp -= amount
	print("Oberwałem! Zostało HP: ", current_hp)
	
	if health_bar:
		health_bar.value = current_hp
		
	# Błysk na czerwono (Visual Feedback)
	modulate = Color(1, 0, 0) # Zmienia kolor łodzi na czerwony
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1) # Wraca do normalnych kolorów
	
	# Sprawdzamy czy łódź zatonęła
	if current_hp <= 0:
		die()

func die() -> void:
	print("GAME OVER - Łódź zatonęła!")
	GameState.is_game_over = true
	hide() # Ukrywamy łódź
	set_physics_process(false)
	
	# KLUCZOWA POPRAWKA: Wyłączamy automat strzelający po śmierci łodzi!
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
	var harpoon = harpoon_scene.instantiate()
	get_parent().add_child(harpoon)
	harpoon.global_position = global_position
	
	var shoot_dir = (target_position - global_position).normalized()
	harpoon.direction = shoot_dir
	harpoon.rotation = shoot_dir.angle() + PI/2
	
	if shoot_sound:
		shoot_sound.play()
