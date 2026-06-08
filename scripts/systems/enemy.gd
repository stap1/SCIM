extends CharacterBody2D

@export var speed: float = 80.0
@export var max_health: float = 10.0

var health: float
var is_dying: bool = false
var target: Node2D = null

func _ready() -> void:
	health = max_health
	add_to_group("enemies")

	if has_node("SpawnSound"):
		$SpawnSound.play()

	# Kontakt-damage do gracza: CharacterBody2D nie emituje body_entered,
	# wiec wykrywamy kontakt dzieckiem Area2D "DamageArea".
	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_damage_area_body_entered)

func set_target(t: Node2D) -> void:
	target = t

func _physics_process(_delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return

	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if target == null:
		return

	velocity = (target.global_position - global_position).normalized() * speed
	move_and_slide()

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		die()

func die() -> void:
	# Death guard: pierwsza smierc wygrywa, kolejne wywolania ignorowane (brak podwojnego queue_free).
	if is_dying:
		return
	is_dying = true

	set_physics_process(false)

	# Chowamy tylko grafike, by czasteczki dokonczyly animacje.
	if has_node("Sprite2D"):
		$Sprite2D.hide()

	# Wylaczamy wykrywanie kontaktu, by martwa meduza nie zadawala obrazen ani nie byla ponownie trafiana.
	if has_node("DamageArea"):
		$DamageArea.set_deferred("monitoring", false)
		$DamageArea.set_deferred("monitorable", false)

	if has_node("DeathParticles"):
		$DeathParticles.emitting = true

	if has_node("DeathSound"):
		$DeathSound.play()

	# Czekamy az czasteczki opadna, dopiero potem niszczymy obiekt.
	await get_tree().create_timer(1.0).timeout
	queue_free()

# --- Kontakt z lodzia (kamikaze) ---
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(20.0)
		die()
