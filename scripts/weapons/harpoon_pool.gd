extends Node

# Pula harpunow (Object Pooling). Tworzy do pool_size harpunow i wypozycza nieaktywne.
# Harpuny sa deaktywowane (active=false, hide), NIGDY queue_free - brak wyciekow obiektow.

# Stan amunicji (dostepne/wszystkie) - emitowany przy kazdej zmianie. HUD slucha i odswieza
# licznik event-driven (koniec pollingu 60x/s w boat.gd).
signal ammo_changed(available: int, total: int)

const HarpoonScene := preload("res://scenes/weapons/harpoon.tscn")

@export var pool_size: int = GameConfig.HARPOON_POOL_SIZE

var _pool: Array = []

func _ready() -> void:
	add_to_group("harpoon_pool")
	for i in pool_size:
		_create_harpoon()
	_emit_ammo() # stan poczatkowy dla sluchaczy gotowych po puli

func _create_harpoon() -> Node:
	var harpoon = HarpoonScene.instantiate()
	add_child(harpoon)
	# Zmiana stanu harpuna (wystrzal/uspienie) -> odswiez licznik amunicji.
	harpoon.availability_changed.connect(_emit_ammo)
	_pool.append(harpoon)
	return harpoon

func _emit_ammo() -> void:
	ammo_changed.emit(available_count(), total_count())

# Zwraca pierwszy nieaktywny harpun; jesli wszystkie aktywne, tworzy nowy do limitu pool_size,
# w przeciwnym razie null. Pula nigdy nie przekracza pool_size.
func get_harpoon():
	for harpoon in _pool:
		if not harpoon.active:
			return harpoon
	if _pool.size() < pool_size:
		return _create_harpoon()
	return null

func available_count() -> int:
	var n := 0
	for harpoon in _pool:
		if not harpoon.active:
			n += 1
	return n

func total_count() -> int:
	return _pool.size()
