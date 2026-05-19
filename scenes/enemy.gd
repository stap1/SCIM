extends Area2D

var speed = 150.0
var player_node = null

func _ready():
	player_node = get_parent().get_node_or_null("Player")
	
	# Odtwarzamy dźwięk spawnu/hitu
	$SpawnSound.play()
	
	# Losujemy, ile sekund pożyje dany wróg (od 3 do 8 sekund)
	var random_lifetime = randf_range(3.0, 8.0)
	await get_tree().create_timer(random_lifetime).timeout
	die()

func _process(delta):
	if player_node != null:
		var direction = (player_node.position - position).normalized()
		position += direction * speed * delta

# Prawdziwa funkcja umierania, gotowa na dodanie strzelania!
func die():
	# 1. Zatrzymujemy wroga
	set_process(false)
	
	# 2. Ukrywamy wroga
	hide()
	
	# 3. Odtwarzamy dźwięk śmierci
	$DeathSound.play()
	
	# 4. Czekamy aż dźwięk przestanie grać
	await $DeathSound.finished
	
	# 5. Całkowicie usuwamy wroga
	queue_free()
