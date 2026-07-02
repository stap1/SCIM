class_name DangerWave
extends FoamWave

# Fala przeciwnosci (gameplay): lekko wieksza i wyrazniejsza od fali ambientowej.
# Pas piany wzdluz luku niesie PRAD: lodz plynaca Z fala przyspiesza, plynaca POD
# fale delikatnie zwalnia (latwa do uniknieci wstega - mozna ja ograc w obie strony).
# Wrogow nie dotyczy (to trud rybaka, nie morza przeciw morzu).

# Fabryka fali gameplayowej (setup z FoamWave + wyrazniejszy wyglad).
static func make_danger(start_pos: Vector2, dir: Vector2, move_speed: float,
		radius: float, travel_time: float) -> DangerWave:
	var w := DangerWave.new()
	w.setup(start_pos, dir, move_speed, radius, travel_time)
	w._apply_danger_look()
	return w

func _enter_tree() -> void:
	add_to_group("danger_waves") # lodz znajduje aktywne fale przez grupe

# Gestsza i wyrazniejsza piana niz fala ambientowa - gracz musi ja czytac jako obiekt.
func _apply_danger_look() -> void:
	amount = GameConfig.FOAM_WAVE_ARC_POINTS * 3
	color = Color(1.0, 1.0, 1.0, GameConfig.DANGER_WAVE_ALPHA)
	scale_amount_min *= 1.2
	scale_amount_max *= 1.2

# Czy punkt swiata lezy w pasie dzialania pradu (wstega wokol luku piany).
func covers_point(world_pos: Vector2) -> bool:
	return arc_band_contains(to_local(world_pos), _radius,
		deg_to_rad(GameConfig.FOAM_WAVE_SPAN_DEG), GameConfig.DANGER_WAVE_BAND_PX)

# --- Czyste funkcje (testowalne bez drzewa scen) ---

# Czy punkt (w ukladzie lokalnym fali: luk wokol +X) lezy w pasie o gruboci band_px
# wokol luku o danym promieniu i rozpietosci katowej.
static func arc_band_contains(local_point: Vector2, radius: float, span_rad: float,
		band_px: float) -> bool:
	var dist := local_point.length()
	if absf(dist - radius) > band_px:
		return false
	if dist < 0.001:
		return false
	return absf(atan2(local_point.y, local_point.x)) <= span_rad * 0.5

# Mnoznik predkosci lodzi w pradzie fali: iloczyn skalarny kierunku ruchu gracza
# i kierunku fali decyduje o znaku (z fala szybciej, pod fale wolniej); prostopadle
# neutralnie. "Delikatne" - wartosci boost/slow trzyma GameConfig.
static func current_multiplier(move_dir: Vector2, wave_dir: Vector2,
		boost_with: float, slow_against: float) -> float:
	if move_dir == Vector2.ZERO or wave_dir == Vector2.ZERO:
		return 1.0
	var dot := move_dir.normalized().dot(wave_dir.normalized())
	return 1.0 + dot * (boost_with if dot > 0.0 else slow_against)

# Kierunek nowej fali z wartosci losowej [0,1]. JEDYNE zrodlo kierunku - przyszla
# zmiana generowania (np. pogoda/pory sesji) podmienia te funkcje w jednym miejscu.
static func roll_direction(rng_value: float) -> Vector2:
	return Vector2.RIGHT.rotated(clampf(rng_value, 0.0, 1.0) * TAU)
