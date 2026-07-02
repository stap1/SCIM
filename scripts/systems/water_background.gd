extends ColorRect

# Tlo wody podaza za kamera, by zawsze wypelniac widok (swiat jest wiekszy niz ColorRect).
# Fale sa zakotwiczone w SWIECIE (shader czyta pozycje swiatowa przez MODEL_MATRIX), wiec
# mimo podazania prostokata woda nie "przykleja sie" do ekranu - lodz plynie nad nia.
#
# Dodatkowo (tanio, bez kosztu per piksel):
# - kolor morza plynie z czasem sesji: jasny poranek -> ciemna ton przed bossem
#   (dwa uniformy raz na klatke),
# - rzadkie rozblyski slonca: male stemple w WakeField w losowych punktach kadru.

var _glint_timer: float = 0.0
var _field: WakeField = null

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		global_position = cam.get_screen_center_position() - size * 0.5
	_update_session_tint()
	_tick_glints(delta)

# Kolor doby: lerp barw wody wzgledem postepu sesji (czysta funkcja + 2 uniformy).
func _update_session_tint() -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var total := float(SettingsStore.session_seconds(SettingsStore.session_length_min))
	var cols := water_colors_for(GameState.time, total)
	mat.set_shader_parameter("water_color", cols["water"])
	mat.set_shader_parameter("wave_color", cols["wave"])

# Czysta funkcja: kolory wody dla danego momentu sesji (0 -> poranek, koniec -> zmierzch).
static func water_colors_for(time_s: float, total_s: float) -> Dictionary:
	var t := clampf(time_s / maxf(total_s, 1.0), 0.0, 1.0)
	return {
		"water": GameConfig.WATER_COLOR_DAWN.lerp(GameConfig.WATER_COLOR_DUSK, t),
		"wave": GameConfig.WAVE_COLOR_DAWN.lerp(GameConfig.WAVE_COLOR_DUSK, t),
	}

# Rozblyski slonca: pojedynczy maly stempel piany w losowym punkcie kadru co interwal.
# Reuzywa WakeField (jeden rysownik, twardy limit) - zero nowych systemow czastek.
func _tick_glints(delta: float) -> void:
	if GameState.is_game_over:
		return
	_glint_timer -= delta
	if _glint_timer > 0.0:
		return
	_glint_timer = GameConfig.WATER_GLINT_INTERVAL
	if _field == null or not is_instance_valid(_field):
		_field = get_tree().get_first_node_in_group("wake_field") as WakeField
		if _field == null:
			return
	var pos := global_position + Vector2(randf() * size.x, randf() * size.y)
	_field.deposit(pos, Vector2.ZERO,
		randf_range(GameConfig.WATER_GLINT_SCALE_MIN, GameConfig.WATER_GLINT_SCALE_MAX))
