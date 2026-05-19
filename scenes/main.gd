extends Node2D

# Ładujemy scenę wroga
var enemy_scene = preload("res://scenes/enemy.tscn")

@onready var spawn_timer = $Timer

func _ready():
	# Łączymy sygnał Timera z funkcją tworzącą wroga
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	var new_enemy = enemy_scene.instantiate()
	
	# Losujemy pozycję na ekranie
	var random_x = randf_range(100, 800)
	var random_y = randf_range(100, 500)
	new_enemy.position = Vector2(random_x, random_y)
	
	add_child(new_enemy)
	print("Pojawił się wróg!")
