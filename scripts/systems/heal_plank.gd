extends Area2D

# Dryfujaca deska - rybak lata nia kadlub. Przy kontakcie z lodzia leczy gracza
# (raz - guard is_collected). Niezebrana znika po lifetime. Wzorzec jak xp_orb.

@export var heal_amount: float = GameConfig.HEAL_PLANK_AMOUNT
@export var lifetime: float = GameConfig.HEAL_PLANK_LIFETIME

var is_collected: bool = false
var _age: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_drift()

# Dryf: dwa Tweeny o roznych okresach (bob pionowy + sway obrotu) na Sprite2D - nieregularne
# kolysanie deski na wodzie. Wszystkie wlasnosci Sprite'a wolne (deska statyczna).
func _start_drift() -> void:
	var sprite := get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var base_y: float = sprite.position.y
	var base_r: float = sprite.rotation
	var hb: float = GameConfig.HEAL_PLANK_BOB_PERIOD * 0.5
	var tb := create_tween().set_loops()
	tb.tween_property(sprite, "position:y", base_y - GameConfig.HEAL_PLANK_BOB_AMOUNT, hb).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tb.tween_property(sprite, "position:y", base_y + GameConfig.HEAL_PLANK_BOB_AMOUNT, hb).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var hs: float = GameConfig.HEAL_PLANK_SWAY_PERIOD * 0.5
	var ts := create_tween().set_loops()
	ts.tween_property(sprite, "rotation", base_r - GameConfig.HEAL_PLANK_SWAY_AMOUNT, hs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ts.tween_property(sprite, "rotation", base_r + GameConfig.HEAL_PLANK_SWAY_AMOUNT, hs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
