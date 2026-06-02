extends Area2D

var speed = 150.0
var player_node = null

func _ready():
	add_to_group("enemies")
	player_node = get_tree().get_first_node_in_group("player")
	
	if has_node("SpawnSound"):
		$SpawnSound.play()
		
	# NOWE: Nasłuchujemy, czy meduza fizycznie wpadła na ciało gracza (łódź)
	body_entered.connect(_on_body_entered)

func _process(delta):
	if GameState.is_paused or GameState.is_game_over:
		return

	if player_node == null or not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")
	
	if player_node == null:
		return
		
	var direction = (player_node.global_position - global_position).normalized()
	position += direction * speed * delta

func die():
	set_process(false)
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	if has_node("DeathSound"):
		$DeathSound.play()
		await $DeathSound.finished
	
	queue_free()

# --- NOWA FUNKCJA: ZADAWANIE OBRAŻEŃ ---
func _on_body_entered(body: Node2D) -> void:
	# Sprawdzamy, czy obiekt z którym się zderzyliśmy to łódź gracza
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(20.0) # Zadajemy 20 pkt obrażeń
		die() # Meduza wybucha po ugryzieniu (styl kamikadze)
