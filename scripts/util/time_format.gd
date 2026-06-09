class_name TimeFormat
extends RefCounted

# Wspolne formatowanie czasu - jedno zrodlo (dedup: bylo kopiowane w hud.gd i game_over.gd).

# Sekundy -> "mm:ss". mmss(75.0) == "01:15". Minuty nie sa zawijane (np. 3661 -> "61:01").
static func mmss(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
