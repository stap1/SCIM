extends CharacterBody2D

@export var max_speed: float = 250.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0

func _ready() -> void:
	# Rejestrujemy łódź w grupie "player" wg specyfikacji, żeby wrogowie nas znaleźli
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Zabezpieczenie przed ruchem w menu lub pauzie
	if GameState.is_paused or GameState.is_game_over:
		return
		
	_handle_movement(delta)
	move_and_slide()

func _handle_movement(delta: float) -> void:
	# PANCERNY TEST: Czytamy fizyczne strzałki i WASD na sztywno z klawiatury!
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
