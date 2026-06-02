extends Area2D

@export var speed: float = 400.0
@export var damage: float = 1.0

var direction: Vector2 = Vector2.ZERO

# NOWE: Referencja do głośnika z dźwiękiem trafienia w meduzę
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

func _ready() -> void:
	area_entered.connect(_on_any_collision)
	body_entered.connect(_on_any_collision)
	
	# Jeśli w nic nie trafi, harpun sam zniknie po 3 sekundach
	await get_tree().create_timer(3.0).timeout
	# Zabezpieczenie: jeśli harpun właśnie odtwarza dźwięk trafienia, nie usuwamy go przedwcześnie
	if hit_sound and not hit_sound.playing:
		queue_free()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		position += direction * speed * delta

# TUTAJ WSKAKUJE TA FUNKCJA Z DŹWIĘKIEM ŚMIERCI:
func _on_any_collision(something: Node) -> void:
	print("!!! KONTROLNY ALERT: Harpun fizycznie czegoś dotknął: ", something.name)
	
	var enemy_node = null
	if something.has_method("die"):
		enemy_node = something
	elif something.get_parent() and something.get_parent().has_method("die"):
		enemy_node = something.get_parent()
		
	if enemy_node:
		# 1. Odpalamy dźwięk śmierci meduzy z poziomu harpuna
		if hit_sound:
			hit_sound.play()
		
		# 2. Zabijamy meduzę
		enemy_node.die()
		
		# 3. Ukrywamy harpun i wyłączamy mu kolizje, żeby nie uderzył w nic dwa razy
		visible = false
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# 4. Czekamy, aż dźwięk skończy się odtwarzać, zanim skasujemy harpun z pamięci
		if hit_sound:
			await hit_sound.finished
		queue_free()
