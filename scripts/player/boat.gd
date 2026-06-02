extends CharacterBody2D

@export var max_speed: float = 220.0     # Zmniejszamy prędkość maksymalną, żeby łatwiej było panować nad łodzią
@export var acceleration: float = 600.0  # Zwiększamy przyspieszenie – łódź szybciej reaguje na kliknięcie i nie muli na starcie
@export var friction: float = 700.0      # Dużo większe hamowanie! Teraz łódź szybciej się zatrzymuje i mniej "driftuje" na wodzie
@export var rotation_speed: float = 5.0  # Trochę wolniejszy obrót kadłuba, żeby nie kręciła się jak szalona

var harpoon_scene = preload("res://scenes/weapons/harpoon.tscn")

@onready var weapon_timer: Timer = $WeaponTimer
# NOWE: Odniesienie do głośnika z dźwiękiem wystrzału w drzewie węzłów łodzi
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

func _ready() -> void:
	add_to_group("player")
	if weapon_timer:
		if weapon_timer.timeout.is_connected(_on_weapon_timer_timeout):
			weapon_timer.timeout.disconnect(_on_weapon_timer_timeout)
		weapon_timer.timeout.connect(_on_weapon_timer_timeout)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	move_and_slide()
	
	# PŁYNNE I MOBILNE OBRACANIE KADŁUBA:
	# Jeśli łódź płynie, to zamiast natychmiastowego obrotu, używamy lerp_angle(), 
	# co daje piękny, płynny efekt skręcania łodzi na wodzie!
	if velocity.length() > 10: # sprawdzamy czy na pewno płynie, a nie lekko drży
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
	
	# Płynne rozpędzanie i hamowanie na wodzie
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

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
	
	# NOWE: Odpalenie dźwięku wystrzału z harpunu!
	if shoot_sound:
		shoot_sound.play()
