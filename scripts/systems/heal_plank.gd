extends Area2D

# Dryfujaca deska - rybak lata nia kadlub. Przy kontakcie z lodzia leczy gracza
# (raz - guard is_collected). Niezebrana znika po lifetime. Wzorzec jak xp_orb.

@export var heal_amount: float = GameConfig.HEAL_PLANK_AMOUNT
@export var lifetime: float = GameConfig.HEAL_PLANK_LIFETIME

var is_collected: bool = false
var _age: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	if GameState.is_paused or GameState.is_game_over:
		return
	_age += delta
	if _age >= lifetime:
		_despawn()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	AudioManager.play_sfx("heal") # ODPALA DŹWIĘK LECZENIA
	GameState.heal(heal_amount)
	queue_free()

func _despawn() -> void:
	if is_collected:
		return
	is_collected = true
	queue_free()
