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

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	# Subtelny kilwater za plynacym wrogiem - jak u lodzi gracza, oszczedniejszy (web/perf).
	WakeTrail.attach_to(self, GameConfig.WAKE_AMOUNT_ENEMY, _wake_reference_speed())

# Predkosc "pelnej smugi" wroga: jego wlasna predkosc (podklasy maja speed/track_speed).
func _wake_reference_speed() -> float:
	if "speed" in self:
		return maxf(float(get("speed")), 1.0)
	if "track_speed" in self:
		return maxf(float(get("track_speed")), 1.0)
	return GameConfig.PLAYER_MAX_SPEED

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
