extends Node

# Autoload "PickupFx": efekt zbioru orba XP. Liczy combo (czas rzeczywisty - reset po
# XP_COMBO_RESET_TIME), spawnuje jednorazowy blysk (CPUParticles2D auto-free, sila wg combo)
# i gra dzwiek xp_pickup z rosnacym pitchem. Reset combo na nowa sesje.

const PickupBurstScene := preload("res://scenes/fx/pickup_burst.tscn")

var _combo: int = 0
var _last_ms: int = 0

func _ready() -> void:
	GameState.session_reset.connect(_reset_combo)

func _reset_combo() -> void:
	_combo = 0
	_last_ms = 0

# Blysk + dzwiek w miejscu zebrania. parent = wezel, pod ktorym spawnowac burst (np. swiat gry).
func flash_at(pos: Vector2, parent: Node) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_ms <= int(GameConfig.XP_COMBO_RESET_TIME * 1000.0):
		_combo = mini(_combo + 1, GameConfig.XP_COMBO_MAX)
	else:
		_combo = 0
	_last_ms = now

	if parent != null and is_instance_valid(parent):
		var burst := PickupBurstScene.instantiate()
		parent.add_child(burst)
		burst.global_position = pos
		if burst.has_method("set_intensity"):
			burst.set_intensity(_combo)

	var pitch: float = 1.0 + float(_combo) * GameConfig.XP_COMBO_PITCH_STEP
	AudioManager.play_sfx_pitched("xp_pickup", pitch)

# Tylko do testow/diagnostyki.
func combo() -> int:
	return _combo
