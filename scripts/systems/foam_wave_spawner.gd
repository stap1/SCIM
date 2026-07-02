class_name FoamWaveSpawner
extends Node

# Ambientowe spienione fale: co losowy odstep (GameConfig.FOAM_WAVE_INTERVAL_*)
# tworzy FoamWave w okolicy widoku gracza. Czysto wizualne tlo morza; przyszla
# ewolucja w "niebezpieczne fale" (gameplay) - patrz FoamWave.

var _timer: float = 0.0

func _ready() -> void:
	_timer = FoamWave.next_interval(randf(),
		GameConfig.FOAM_WAVE_INTERVAL_MIN, GameConfig.FOAM_WAVE_INTERVAL_MAX)

func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = FoamWave.next_interval(randf(),
		GameConfig.FOAM_WAVE_INTERVAL_MIN, GameConfig.FOAM_WAVE_INTERVAL_MAX)
	_spawn_near_player()

func _spawn_near_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	# Losowy punkt w obrebie widocznego kadru wokol gracza (fala pojawia sie NA ekranie).
	var vp_size := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	if cam != null and cam.zoom.x > 0.0 and cam.zoom.y > 0.0:
		vp_size /= cam.zoom
	var offset := Vector2(randf_range(-0.4, 0.4) * vp_size.x, randf_range(-0.4, 0.4) * vp_size.y)
	spawn_wave_at(player.global_position + offset)

# Tworzy fale w zadanym punkcie swiata (losowy kierunek/tempo/promien). Publiczne - testy.
func spawn_wave_at(world_pos: Vector2) -> FoamWave:
	var wave := FoamWave.make(world_pos, _ambient_direction(),
		randf_range(GameConfig.FOAM_WAVE_SPEED_MIN, GameConfig.FOAM_WAVE_SPEED_MAX),
		randf_range(GameConfig.FOAM_WAVE_RADIUS_MIN, GameConfig.FOAM_WAVE_RADIUS_MAX),
		GameConfig.FOAM_WAVE_TRAVEL_TIME)
	add_child(wave)
	return wave

# Kierunek fali ambientowej: gdy na ekranie zyje fala przeciwnosci (DangerWave),
# ambient plynie w TYM SAMYM kierunku - zero sprzecznych wskazowek dla gracza.
func _ambient_direction() -> Vector2:
	var danger := get_tree().get_first_node_in_group("danger_waves")
	if danger != null and is_instance_valid(danger) and danger.has_method("move_dir"):
		return danger.move_dir()
	return Vector2.RIGHT.rotated(randf() * TAU)
