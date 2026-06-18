extends CPUParticles2D

# Jednorazowy blysk zebrania orba XP (zlote iskry). Sam sie odpala (emitting=true, one_shot
# w .tscn) i zwalnia po zyciu. set_intensity skaluje liczbe/rozmiar iskier z combo.

func _ready() -> void:
	await get_tree().create_timer(GameConfig.DEATH_BURST_LIFETIME).timeout
	queue_free()

# Skala efektu wg combo (seria zbiorow = mocniejszy blysk).
func set_intensity(combo: int) -> void:
	var f: float = 1.0 + clampf(float(combo) / float(GameConfig.XP_COMBO_MAX), 0.0, 1.0)
	amount = maxi(4, int(float(amount) * f))
	scale_amount_min *= f
	scale_amount_max *= f
