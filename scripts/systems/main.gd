extends Node2D

# Ładujemy scenę wroga
var enemy_scene = preload("res://scenes/enemies/enemy.tscn")

@onready var spawn_timer = $Timer

# NAPRAWIONE: Bezpośrednie odniesienie do nowego węzła TimeLabel w scenie głównej
@onready var time_label: Label = $TimeLabel

func _ready():
	# Łączymy sygnał Timera z funkcją tworzącą wroga
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Resetujemy czas globalny na starcie gry
	if "time" in GameState:
		GameState.time = 0.0

func _process(delta: float) -> void:
	# 1. Dodajemy upływający czas do zmiennej w GameState
	if "is_paused" in GameState and not GameState.is_paused:
		if "is_game_over" in GameState and not GameState.is_game_over:
			GameState.time += delta
	else:
		# Zabezpieczenie: jeśli nie ma jeszcze pauzy/game over w GameState, czas i tak leci
		if not "is_paused" in GameState:
			GameState.time += delta

	# 2. Aktualizujemy napis na ekranie (str(int(...)) zamienia ułamki na ładne, równe sekundy)
	if time_label:
		time_label.text = "Czas: " + str(int(GameState.time)) + "s"

func _on_spawn_timer_timeout():
	var new_enemy = enemy_scene.instantiate()
	
	# Losujemy pozycję na ekranie
	var random_x = randf_range(100, 800)
	var random_y = randf_range(100, 500)
	new_enemy.position = Vector2(random_x, random_y)
	
	add_child(new_enemy)
	print("Pojawił się wróg!")
