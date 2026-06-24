extends Area2D

# Orb XP wypadajacy z wroga. W zasiegu magnesu leci ku graczowi; w promieniu
# pickup_radius zostaje zebrany (jedna sciezka: dystans w _physics_process, raz - guard is_collected).

# Wartosci startowe z GameConfig (jedyne zrodlo balansu).
@export var xp_value: int = GameConfig.XP_ORB_VALUE
@export var pickup_radius: float = GameConfig.XP_PICKUP_RADIUS
@export var magnet_speed: float = GameConfig.XP_MAGNET_SPEED
@export var magnet_range: float = GameConfig.XP_MAGNET_RANGE
# Po tylu sekundach aktywnej gry niezebrany orb znika - zapobiega kumulacji orbow
# spoza zasiegu magnesu (audyt P0.1: orby nie mialy capa/lifetime).
@export var lifetime: float = GameConfig.XP_ORB_LIFETIME

var is_collected: bool = false
var _age: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	add_to_group("xp_orbs")  # do liczenia capa orbow w spawnerze
	# Upgrade resource_magnet zwieksza zasieg zbierania nowo powstalych orbow.
	magnet_range *= GameState.magnet_range_mult
	# Gruby orb (bossa) jest wiekszy wizualnie. xp_value ustawiany przed add_child, wiec tu pewny.
	if xp_value > 1:
		var sprite := get_node_or_null("Sprite2D")
		if sprite:
			sprite.scale *= GameConfig.XP_ORB_FAT_SCALE

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	if GameState.is_paused or GameState.is_game_over:
		return

	# Lifetime liczony tylko podczas aktywnej gry (pauza/koniec gry wstrzymuja starzenie).
	_age += delta
	if _age >= lifetime:
		_despawn()
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist < pickup_radius:
		_collect()
		return
	if should_magnetize(dist, magnet_range):
		var dir := (_player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta

func _collect() -> void:
	if is_collected:
		return
	is_collected = true              # natychmiast - guard przed podwojnym zebraniem
	
	# Odpalamy dźwięk standardowo. 
	# Stasiek docelowo zamieni to na play_sfx_pitched("xp_pickup", wartosc_combo)
	AudioManager.play_sfx("xp_pickup")
	
	GameState.add_xp(xp_value)       # nagroda od razu (bez ryzyka utraty XP w trakcie animacji)
	var aura := get_node_or_null("GoldenAura")
	if aura != null and aura.has_method("stop"):
		aura.stop()                  # aura nie moze walczyc z wsiakaniem
	PickupFx.flash_at(global_position, get_parent())
	_absorb_and_free()

# Satysfakcjonujace wsiakanie: orb leci do gracza i kurczy sie, potem znika. XP juz przyznane.
func _absorb_and_free() -> void:
	var t := create_tween()
	if _player != null and is_instance_valid(_player):
		t.tween_property(self, "global_position", _player.global_position,
			GameConfig.XP_ORB_ABSORB_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var sprite := get_node_or_null("Sprite2D")
	if sprite != null:
		t.parallel().tween_property(sprite, "scale", sprite.scale * 0.1, GameConfig.XP_ORB_ABSORB_TIME)
	t.tween_callback(queue_free)

# Niezebrany orb po uplywie lifetime - znika bez przyznania XP (is_collected jako guard "orb zniknal").
func _despawn() -> void:
	if is_collected:
		return
	is_collected = true
	queue_free()

# Czysta funkcja: czy orb powinien leciec ku graczowi.
static func should_magnetize(distance: float, magnet_range_value: float) -> bool:
	return distance < magnet_range_value
