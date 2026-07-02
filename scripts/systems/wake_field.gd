class_name WakeField
extends Node2D

# Wspolna warstwa piany kilwaterow: JEDEN wezel rysuje wszystkie stemple piany
# (ring buffer o twardym limicie) zamiast dwoch CPUParticles2D na kazda jednostke.
# To usuwa koszt dziesiatek emiterow przy stadzie wrogow (web/perf) i daje pelna
# kontrole nad odstepem stempli. Zrodla (WakeTrail) odkladaja stemple przez deposit().

var _pos: PackedVector2Array = PackedVector2Array()
var _drift: PackedVector2Array = PackedVector2Array()
var _born_ms: PackedInt64Array = PackedInt64Array()
var _scale: PackedFloat32Array = PackedFloat32Array()
var _head: int = 0
var _any_alive: bool = false

func _ready() -> void:
	add_to_group("wake_field")
	show_behind_parent = true
	var cap := GameConfig.WAKE_MAX_STAMPS
	_pos.resize(cap)
	_drift.resize(cap)
	_born_ms.resize(cap)
	_scale.resize(cap)
	for i in cap:
		_born_ms[i] = -1 # pusty slot

# Odklada stempel piany w pozycji SWIATA. Ring buffer: najstarszy slot nadpisywany -
# twardy limit kosztu niezaleznie od liczby jednostek na ekranie.
func deposit(world_pos: Vector2, drift: Vector2, stamp_scale: float) -> void:
	_pos[_head] = world_pos
	_drift[_head] = drift
	_born_ms[_head] = Time.get_ticks_msec()
	_scale[_head] = stamp_scale
	_head = wrap_index(_head + 1, _born_ms.size())
	_any_alive = true

func _process(_delta: float) -> void:
	if _any_alive:
		queue_redraw()

func _draw() -> void:
	var tex := WakeTrail.foam_texture()
	var now := Time.get_ticks_msec()
	var life_ms := GameConfig.WAKE_LIFETIME * 1000.0
	var half := float(GameConfig.WAKE_TEXTURE_SIZE) * 0.5
	# Culling: stemple poza kadrem (z marginesem) nie sa rysowane - historia sladow
	# ciagnie sie po mapie, a placi tylko to, co widac.
	var cull_center := Vector2.INF
	var cull_r_sq := INF
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		cull_center = cam.get_screen_center_position()
		var r := visible_radius(get_viewport().get_visible_rect().size, cam.zoom.x,
			GameConfig.WAKE_CULL_MARGIN_PX)
		cull_r_sq = r * r
	var alive := 0
	for i in _born_ms.size():
		if _born_ms[i] < 0:
			continue
		var age := float(now - _born_ms[i]) / life_ms
		if age >= 1.0:
			_born_ms[i] = -1
			continue
		alive += 1
		if _pos[i].distance_squared_to(cull_center) > cull_r_sq:
			continue # zyje, ale poza kadrem - nie rysuj
		var a := fade_alpha(age, GameConfig.WAKE_ALPHA)
		# Dryf na zewnatrz "V": stempel odplywa od osi sladu w miare starzenia.
		var p := to_local(_pos[i] + _drift[i] * age * GameConfig.WAKE_LIFETIME)
		var s := _scale[i]
		draw_texture_rect(tex, Rect2(p - Vector2(half, half) * s, Vector2(half, half) * 2.0 * s),
			false, Color(1.0, 1.0, 1.0, a))
	_any_alive = alive > 0

# --- Czyste funkcje (testowalne bez drzewa scen) ---

# Promien cullingu: polowa dluzszego boku kadru (z korekta zoomu) + margines.
static func visible_radius(vp_size: Vector2, zoom: float, margin_px: float) -> float:
	return maxf(vp_size.x, vp_size.y) * 0.5 / maxf(zoom, 0.001) + margin_px

# Indeks ring buffera z zawijaniem (bezpieczny dla dowolnego rozmiaru > 0).
static func wrap_index(index: int, size: int) -> int:
	if size <= 0:
		return 0
	return index % size

# Krycie piany: pelne na starcie zycia stempla, liniowo do zera na koncu.
static func fade_alpha(age_ratio: float, base_alpha: float) -> float:
	return base_alpha * clampf(1.0 - age_ratio, 0.0, 1.0)
