extends Node

# Platform - jedyne miejsce wiedzy "jaki to build": flaga mobilna (feature "mobile_web"
# z presetu Web Mobile lub natywne platformy dotykowe) + dopasowanie okna i kamery do
# builda pionowego. Jeden project.godot obsluguje oba buildy - pion ustawiany w runtime.

func _ready() -> void:
	# Build pionowy: przestaw bazowy rozmiar canvasu (1152x648 -> 648x1152).
	if is_mobile_build():
		get_window().content_scale_size = portrait_scale_size(get_window().content_scale_size)

static func is_mobile_build() -> bool:
	return OS.has_feature("mobile_web") or OS.has_feature("android") or OS.has_feature("ios")

# Czysta funkcja: pion = zamiana osi bazowego rozmiaru.
static func portrait_scale_size(base: Vector2i) -> Vector2i:
	return Vector2i(base.y, base.x)

# Czysta funkcja: zoom kamery per build (pion widzi podobny obszar gry - lekkie oddalenie).
static func camera_zoom(is_mobile: bool) -> float:
	return GameConfig.CAMERA_ZOOM_MOBILE if is_mobile else 1.0
