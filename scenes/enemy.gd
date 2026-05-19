extends Area2D

# Prędkość z jaką wróg płynie w pikselach na sekundę
var speed = 150.0

# Zmienna, w której zapamiętamy gdzie jest gracz
var player_node = null

func _ready():
	# Szukamy w scenie głównej węzła o nazwie "Player"
	# Używamy get_parent(), ponieważ wróg jest dzieckiem sceny Main, tak samo jak gracz
	player_node = get_parent().get_node_or_null("Player")

func _process(delta):
	# Jeśli gracz istnieje na mapie...
	if player_node != null:
		# 1. Obliczamy kierunek od wroga do gracza
		var direction = (player_node.position - position).normalized()
		
		# 2. Przesuwamy wroga w tym kierunku z określoną prędkością
		position += direction * speed * delta
