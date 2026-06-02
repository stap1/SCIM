extends Area2D

var speed = 150.0
var player_node = null

func _ready():
	# Szukamy nowej łodzi bezpiecznie przez Grupę "player"
	player_node = get_tree().get_first_node_in_group("player")
	
	# Odtwarzamy dźwięk spawnu/hitu
	$SpawnSound.play()
	
	# Losujemy, ile sekund pożyje dany wróg (od 3 do 8 sekund)
	var random_lifetime = randf_range(3.0, 8.0)
	await get_tree().create_timer(random_lifetime).timeout
	die()

func _process(delta):
	# Zabezpieczenie przed ruchem podczas pauzy globalnej
	if GameState.is_paused or GameState.is_game_over:
		return

	# Jeśli nie mamy gracza lub referencja jest nieważna, szukamy go ponownie
	if player_node == null or not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player")
	
	# Jeśli łódka jeszcze fizycznie nie zdążyła się załadować – czekamy na kolejną klatkę
	if player_node == null:
		return
		
	# Prawdziwy, automatyczny ruch w stronę globalnej pozycji nowej łodzi
	var direction = (player_node.global_position - global_position).normalized()
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
