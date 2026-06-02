extends Node2D

var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
@onready var spawn_timer = $Timer
@onready var time_label: Label = $TimeLabel

# Celujemy bezpośrednio w ColorRect, który teraz trzyma całe UI śmierci
@onready var game_over_bg = $GameOverScreen/ColorRect
@onready var restart_button = $GameOverScreen/ColorRect/RestartButton

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	GameState.is_game_over = false
	if "is_paused" in GameState:
		GameState.is_paused = false
	if "time" in GameState:
		GameState.time = 0.0
		
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
		
	# Na starcie gry upewniamy się, że tło jest niewidoczne i przezroczyste
	if game_over_bg:
		game_over_bg.hide()
		game_over_bg.modulate.a = 0.0

func _process(delta: float) -> void:
	if not GameState.is_game_over:
		GameState.time += delta
		if time_label:
			time_label.text = "Czas: " + str(int(GameState.time)) + "s"
	else:
		# Odpalamy bajeranckie wejście tylko raz, gdy gracz umrze i tło wciąż jest schowane
		if game_over_bg and not game_over_bg.visible:
			trigger_game_over_effects()

func trigger_game_over_effects() -> void:
	if game_over_bg:
		game_over_bg.show() # Otwieramy zamknięte oko węzła w kodzie
		
		# Animujemy płynne wyłonienie z mroku (od 0.0 do 1.0 w 0.6 sekundy)
		var tween = create_tween()
		tween.tween_property(game_over_bg, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		print("Kinowy efekt Game Over działa perfekcyjnie!")

func _on_spawn_timer_timeout():
	if GameState.is_game_over:
		return
		
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	var dynamic_limit = 5 + int(GameState.time / 15.0)
	var max_allowed = min(dynamic_limit, 30) 
	
	if current_enemies >= max_allowed:
		return 
		
	var new_enemy = enemy_scene.instantiate()
	var random_x = randf_range(100, 800)
	var random_y = randf_range(100, 500)
	new_enemy.position = Vector2(random_x, random_y)
	
	add_child(new_enemy)

func _on_restart_pressed():
	get_tree().reload_current_scene()
