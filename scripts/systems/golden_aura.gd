extends Node

# Zlota aura zbieralnego obiektu: pulsujace rozjasnienie (modulate) + oddech (scale) Sprite'a
# rodzica - dwa Tweeny o roznych okresach ("oddychajace swiatlo"). Tween, nie shader (dziesiatki
# instancji). stop() zabija wlasne Tweeny i przywraca baze - konieczne, by aura nie walczyla
# z animacja wsiakania w _collect. Respektuje reduce_flashing (wariant statyczny).

@export var glow_color: Color = Color(1.5, 1.3, 0.6, 1.0)
@export var glow_period: float = 1.1
@export var scale_amount: float = 0.08
@export var scale_period: float = 1.5

var _sprite: Node2D
var _base_modulate: Color
var _base_scale: Vector2
var _tweens: Array = []

func _ready() -> void:
	var parent := get_parent()
	if parent == null:
		return
	_sprite = parent.get_node_or_null("Sprite2D")
	if _sprite == null:
		return
	_base_modulate = _sprite.modulate
	_base_scale = _sprite.scale
	# Dostepnosc: bez migotania - statyczne lekkie rozjasnienie zamiast pulsu.
	if not SettingsStore.should_flash(SettingsStore.reduce_flashing):
		_sprite.modulate = _base_modulate.lerp(glow_color, 0.4)
		return
	_glow()
	_breath()

func _glow() -> void:
	var h: float = glow_period * 0.5
	var t := create_tween().set_loops()
	t.tween_property(_sprite, "modulate", glow_color, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_sprite, "modulate", _base_modulate, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tweens.append(t)

func _breath() -> void:
	var h: float = scale_period * 0.5
	var t := create_tween().set_loops()
	t.tween_property(_sprite, "scale", _base_scale * (1.0 + scale_amount), h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_sprite, "scale", _base_scale, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tweens.append(t)

# Zabija aure (przed wsiakaniem orba). Bezpieczne do wielokrotnego wywolania.
func stop() -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()
	if _sprite != null:
		_sprite.modulate = _base_modulate
