extends Area2D

# Emitowany gdy zmienia sie stan active (wystrzal/uspienie) - pula nasluchuje, by
# odswiezyc licznik amunicji event-driven (bez pollingu).
signal availability_changed

# Wartosci startowe z GameConfig (jedyne zrodlo balansu).
@export var speed: float = GameConfig.HARPOON_SPEED
@export var damage: float = GameConfig.HARPOON_DAMAGE

var direction: Vector2 = Vector2.ZERO
var active: bool = false
var lifetime: float = 0.0
# Przebijanie: przez ilu DODATKOWYCH wrogow harpun przelatuje zanim zniknie (0 = jak dotad).
var pierce: int = 0
# Wrogowie juz trafieni w tym locie - anty-podwojne trafienie tego samego celu.
var _hit_ids: Array[int] = []

func _ready() -> void:
	area_entered.connect(_on_any_collision)
	body_entered.connect(_on_any_collision)

	# Na starcie harpun usypia samego siebie i czeka w puli.
	deactivate()

func _physics_process(delta: float) -> void:
	# Uspiony harpun calkowicie ignoruje fizyke.
	if not active:
		return

	if direction != Vector2.ZERO:
		position += direction * speed * delta

	# Reczny licznik czasu zycia (bezpieczny dla Object Poolingu).
	lifetime += delta
	if lifetime >= GameConfig.HARPOON_LIFETIME:
		deactivate()

# --- Wybudzenie z puli ---
func fire(start_pos: Vector2, shoot_dir: Vector2, pierce_count: int = 0) -> void:
	global_position = start_pos
	direction = shoot_dir
	rotation = direction.angle() + PI / 2

	lifetime = 0.0
	pierce = pierce_count
	_hit_ids.clear()
	active = true
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	availability_changed.emit()

# --- Uspienie (ZAMIAST queue_free - pooling, brak wyciekow) ---
func deactivate() -> void:
	active = false
	visible = false
	direction = Vector2.ZERO
	pierce = 0
	_hit_ids.clear()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	availability_changed.emit()

# --- Kolizje ---
func _on_any_collision(something: Node) -> void:
	if not active:
		return

	var enemy_node = null
	if something.is_in_group("enemies") and something.has_method("take_damage"):
		enemy_node = something
	elif something.get_parent() and something.get_parent().is_in_group("enemies") and something.get_parent().has_method("take_damage"):
		enemy_node = something.get_parent()

	if enemy_node:
		var eid: int = enemy_node.get_instance_id()
		if _hit_ids.has(eid):
			return # ten wrog juz trafiony w tym locie
		_hit_ids.append(eid)
		AudioManager.play_sfx("hit")
		enemy_node.take_damage(damage)
		# Przebijanie: leci dalej dopoki ma zapas przebic, inaczej zasypia.
		if pierce > 0:
			pierce -= 1
		else:
			deactivate()
