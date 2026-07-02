class_name EnemyBase
extends CharacterBody2D

# Wspolna baza wszystkich wrogow (Jellyfish/Barracuda/Shark oraz mini-boss MotorBoat).
# Zbiera to, co bylo zduplikowane miedzy enemy.gd a motor_boat.gd:
# health / is_dying / target / set_target() / take_damage() / die() / grupa "enemies".
#
# Bazowe wartosci HP/score ustawiaja podklasy w _init() z GameConfig (jedyne zrodlo balansu).
# Warianty (barracuda/shark) nadpisuja eksporty w swoich .tscn.
#
# Punkty rozszerzen dla podklas:
# - _on_health_changed(): reakcja na zmiane HP (np. pasek HP bossa).
# - _on_death(): emisja sygnalu smierci specyficznego dla typu (died / boss_defeated).

@export var max_health: float = 0.0
@export var kill_score: int = 0
# Obrazenia, ktore ten wrog zadaje graczowi na kontakt (per-wrog). Baza = zwykly wrog;
# boss nadpisuje w _init, warianty moga nadpisac w .tscn.
@export var contact_damage: float = GameConfig.ENEMY_CONTACT_DAMAGE

var health: float
var is_dying: bool = false
var target: Node2D = null
# Promien ciala (z CollisionShape2D) - uzywany przez separacje wrogow i kilwater.
var body_radius: float = GameConfig.WAKE_WIDTH_FALLBACK / 2.0

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	body_radius = WakeTrail.body_half_width(self)
	# Losowa faza odswiezania separacji - stado nie liczy O(n^2) w tej samej klatce.
	_sep_phase = randi() % maxi(GameConfig.ENEMY_SEPARATION_EVERY, 1)
	# Subtelny kilwater za plynacym wrogiem - gestosc i szerokosc wynikaja z jednostki.
	WakeTrail.attach_to(self, _wake_reference_speed())

# Predkosc "pelnej smugi" wroga: jego wlasna predkosc (podklasy maja speed/track_speed).
func _wake_reference_speed() -> float:
	if "speed" in self:
		return maxf(float(get("speed")), 1.0)
	if "track_speed" in self:
		return maxf(float(get("track_speed")), 1.0)
	return GameConfig.PLAYER_MAX_SPEED

# --- Status "spowolnienie" (harpun z linka; fundament pod sieci rybackie i bossy) ---

var _slow_mult: float = 1.0
var _slow_left: float = 0.0

# Naklada spowolnienie: slow_mult = docelowy mnoznik predkosci (0.75 = 75% tempa).
# Najsilniejsze spowolnienie wygrywa, czas trwania sie odswieza (bez stackowania w dol).
func apply_slow(slow_mult: float, duration: float) -> void:
	var m := clampf(slow_mult, 0.05, 1.0)
	if _slow_left <= 0.0 or m < _slow_mult:
		_slow_mult = m
	_slow_left = maxf(_slow_left, maxf(duration, 0.0))

# Odliczanie statusu - wolane z _physics_process podklas (maja wlasna petle ruchu).
func tick_slow(delta: float) -> void:
	if _slow_left <= 0.0:
		return
	_slow_left -= delta
	if _slow_left <= 0.0:
		_slow_mult = 1.0

# Aktualny mnoznik predkosci ruchu (1.0 = bez spowolnienia).
func slow_multiplier() -> float:
	return _slow_mult if _slow_left > 0.0 else 1.0

# --- Separacja wrogow: "kolizja na pol rozmiaru" ---

# Czysta funkcja: pchniecie OD sasiada dla jednej pary. Prog = (r1+r2) * factor;
# powyzej progu ZERO, ponizej liniowo do 1.0 przy pelnym nalozeniu. Idealnie
# nalozone ciala (dystans ~0) dostaja deterministyczny kierunek awaryjny.
static func separation_dir(my_pos: Vector2, my_radius: float, other_pos: Vector2,
		other_radius: float, factor: float) -> Vector2:
	var threshold := (my_radius + other_radius) * factor
	if threshold <= 0.0:
		return Vector2.ZERO
	var offset := my_pos - other_pos
	var dist := offset.length()
	if dist >= threshold:
		return Vector2.ZERO
	var strength := 1.0 - dist / threshold
	if dist < 0.001:
		return Vector2.RIGHT * strength
	return offset / dist * strength

# Zatloczenie jednostki [0,1] z ostatniego separation_push - kilwater w scisku
# odklada rzadsze stemple (stado nie muruje jednolitej sciany piany).
var separation_crowding: float = 0.0
# Zapamietane pchniecie separacji + faza odswiezania (koszt O(n^2) liczony co
# ENEMY_SEPARATION_EVERY klatek, fazy per wrog rozlozone losowo - stado nie liczy
# wszystkiego w tej samej klatce).
var _sep_cached: Vector2 = Vector2.ZERO
var _sep_phase: int = 0

# Suma odpychania od sasiadow z grupy "enemies" (dlugosc przycieta do 1.0).
# Boss odpycha innych samym rozmiarem; czy sam przyjmuje pchniecia - decyduje podklasa
# (zwykli wrogowie stosuja push w ruchu, boss nie - jego szarze musza byc przewidywalne).
func separation_push() -> Vector2:
	_sep_phase += 1
	if _sep_phase < GameConfig.ENEMY_SEPARATION_EVERY:
		return _sep_cached # miedzy odswiezeniami dziala ostatnie pchniecie
	_sep_phase = 0
	var push := Vector2.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		# Wszyscy czlonkowie grupy dziedzicza z EnemyBase - typowany cast zamiast
		# kosztownego stringowego `"body_radius" in e` per para per klatka.
		var other := e as EnemyBase
		if other == null or other == self or not is_instance_valid(other):
			continue
		push += separation_dir(global_position, body_radius,
			other.global_position, other.body_radius, GameConfig.ENEMY_SEPARATION_FACTOR)
	_sep_cached = push.limit_length(1.0)
	separation_crowding = _sep_cached.length()
	return _sep_cached

func set_target(t: Node2D) -> void:
	target = t

# Odswieza cel (gracz). Zwraca false, gdy gracza brak - wtedy podklasa nie rusza sie.
func acquire_target() -> bool:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	return target != null

func take_damage(amount: float) -> void:
	if is_dying:
		return
	health -= amount
	_on_health_changed()
	if health <= 0.0:
		die()

func die() -> void:
	# Death guard: pierwsza smierc wygrywa, kolejne wywolania ignorowane
	# (brak podwojnego score / podwojnego queue_free). Regresja #2.
	if is_dying:
		return
	is_dying = true
	GameState.enemies_killed += 1
	GameState.add_score(kill_score)
	_on_death()
	queue_free()

# --- Wirtualne haki (podklasy nadpisuja w miare potrzeb) ---
func _on_health_changed() -> void:
	pass

func _on_death() -> void:
	pass
