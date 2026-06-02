extends Area2D

@export var speed: float = 400.0
@export var damage: float = 1.0

var direction: Vector2 = Vector2.ZERO
var is_active: bool = false
var lifetime: float = 0.0
const MAX_LIFETIME: float = 3.0

@onready var hit_sound: AudioStreamPlayer2D = $HitSound

func _ready() -> void:
	area_entered.connect(_on_any_collision)
	body_entered.connect(_on_any_collision)
	
	# Na samym starcie gry harpun usypia samego siebie i czeka w magazynku
	deactivate()

func _physics_process(delta: float) -> void:
	# Jeśli harpun jest uśpiony, całkowicie ignorujemy jego fizykę
	if not is_active:
		return
		
	if direction != Vector2.ZERO:
		position += direction * speed * delta
		
	# Ręczny licznik czasu (bezpieczny dla Object Poolingu)
	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		deactivate()

# --- FUNKCJA WYBUDZAJĄCA Z PULI ---
func fire(start_pos: Vector2, shoot_dir: Vector2) -> void:
	global_position = start_pos
	direction = shoot_dir
	rotation = direction.angle() + PI/2
	
	lifetime = 0.0
	is_active = true
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

# --- FUNKCJA USYPIAJĄCA (ZAMIAST queue_free) ---
func deactivate() -> void:
	is_active = false
	visible = false
	direction = Vector2.ZERO
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

# --- KOLIZJE ---
func _on_any_collision(something: Node) -> void:
	if not is_active:
		return
		
	var enemy_node = null
	
	if something.is_in_group("enemies") and something.has_method("die"):
		enemy_node = something
	elif something.get_parent() and something.get_parent().is_in_group("enemies") and something.get_parent().has_method("die"):
		enemy_node = something.get_parent()
		
	if enemy_node:
		if hit_sound:
			hit_sound.play()
		
		enemy_node.die()
		
		# Wyłączamy fizykę i ukrywamy harpun, ale pozwalamy dźwiękowi grać
		is_active = false
		visible = false
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# W Puli Obiektów NIE używamy queue_free()! Harpun po prostu zostaje uśpiony w tle.
