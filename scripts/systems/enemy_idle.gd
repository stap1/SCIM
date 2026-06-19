extends Node

# Komponent "idle" wroga: lekkie bujanie (bob, pion) i kolysanie (sway, rot) Sprite'a
# rodzica - Tweenem, nie shaderem (kilka sztuk na raz, tanio). Parametry wg profilu z
# GameConfig.ENEMY_IDLE (jedno zrodlo liczb). NIE rusza ciala (kolizje/statystyki nietkniete).
# Tween dziedziczy process_mode -> pauzuje z drzewem automatycznie.

@export var profile: String = "barracuda"

var _sprite: Node2D

func _ready() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_sprite = parent.get_node_or_null("Sprite2D")
	if _sprite == null:
		return
	var p: Dictionary = GameConfig.ENEMY_IDLE.get(profile, {})
	if p.is_empty():
		return
	_bob(float(p["bob_amount"]), float(p["bob_period"]))
	_sway(float(p["sway_amount"]), float(p["sway_period"]))

func _bob(amount: float, period: float) -> void:
	var base_y: float = _sprite.position.y
	var h: float = period * 0.5
	var t := create_tween().set_loops()
	t.tween_property(_sprite, "position:y", base_y - amount, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_sprite, "position:y", base_y + amount, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _sway(amount: float, period: float) -> void:
	var base_r: float = _sprite.rotation
	var h: float = period * 0.5
	var t := create_tween().set_loops()
	t.tween_property(_sprite, "rotation", base_r - amount, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_sprite, "rotation", base_r + amount, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
