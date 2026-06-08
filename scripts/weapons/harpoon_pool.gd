extends Node

# Pula harpunow (Object Pooling). Tworzy do pool_size harpunow i wypozycza nieaktywne.
# Harpuny sa deaktywowane (active=false, hide), NIGDY queue_free - brak wyciekow obiektow.

const HarpoonScene := preload("res://scenes/weapons/harpoon.tscn")

@export var pool_size: int = 20

var _pool: Array = []

func _ready() -> void:
	add_to_group("harpoon_pool")
	for i in pool_size:
		_create_harpoon()

func _create_harpoon() -> Node:
	var harpoon = HarpoonScene.instantiate()
	add_child(harpoon)
	_pool.append(harpoon)
	return harpoon

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
