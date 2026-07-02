extends SceneTree

# Jednorazowe narzedzie: pakuje dwie heightmapy szumu wody w kanaly R/G JEDNEJ
# tekstury 512x512 (assets/water_noise_rg.png). Shader wody czyta .r i .g z tej
# samej tekstury (2 fetche cache-friendly zamiast 2 roznych tekstur + normal mapy).
# Uruchomienie: Godot --headless --path SCIM -s res://tools/pack_water_noise.gd
#
# UWAGA (prowenience): zrodlowe water_noise.png / water_noise_2.png zostaly usuniete
# z repo po spakowaniu (2026-07-02) - wynikowa water_noise_rg.png jest zrodlem prawdy.
# Do REGENERACJI innego szumu: podstaw nowe zrodla albo uzyj FastNoiseLite
# (get_seamless_image) zamiast load_from_file.

const SIZE := 512

func _initialize() -> void:
	var a := Image.load_from_file("res://assets/water_noise.png")
	var b := Image.load_from_file("res://assets/water_noise_2.png")
	if a == null or b == null:
		push_error("Brak zrodlowych szumow wody")
		quit(1)
		return
	a.resize(SIZE, SIZE, Image.INTERPOLATE_BILINEAR)
	b.resize(SIZE, SIZE, Image.INTERPOLATE_BILINEAR)
	var out := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			out.set_pixel(x, y, Color(a.get_pixel(x, y).r, b.get_pixel(x, y).r, 0.0))
	out.save_png("res://assets/water_noise_rg.png")
	print("OK: assets/water_noise_rg.png (%dx%d, R=szum1, G=szum2)" % [SIZE, SIZE])
	quit(0)
