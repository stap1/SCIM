extends CanvasLayer

# Ekran wyboru ulepszenia. Na sygnal GameState.level_up pauzuje gre i pokazuje 3 karty.
# process_mode = ALWAYS (w .tscn), by przyciski dzialaly mimo get_tree().paused.
# Realne efekty ulepszen dochodza w kroku 15 (Upgrades) - tu emitujemy tylko upgrade_chosen(id).

signal upgrade_chosen(id: String)

# Pula dostepnych ulepszen (id). W kroku 15 dostana realne efekty i opisy.
const UPGRADE_POOL: Array[String] = [
	"faster_attack", "longer_range", "tougher_hull",
	"faster_boat", "resource_magnet", "double_harpoon",
]

@onready var panel: Control = $Panel
@onready var cards: Array = [$Panel/Card0, $Panel/Card1, $Panel/Card2]

var _current_ids: Array[String] = []

func _ready() -> void:
	if panel:
		panel.hide()
	GameState.level_up.connect(_on_level_up)
	for i in cards.size():
		var card = cards[i]
		if card:
			card.pressed.connect(_on_card_pressed.bind(i))

func _on_level_up(_new_level: int) -> void:
	_current_ids = pick_three(UPGRADE_POOL, randi())
	for i in cards.size():
		if cards[i] and i < _current_ids.size():
			_set_card_text(cards[i], _current_ids[i])
	if panel:
		panel.show()
	get_tree().paused = true

func _set_card_text(card: Node, id: String) -> void:
	var label = card.get_node_or_null("Label")
	if label:
		label.text = id
	else:
		card.text = id

func _on_card_pressed(index: int) -> void:
	var id: String = _current_ids[index] if index < _current_ids.size() else ""
	if panel:
		panel.hide()
	get_tree().paused = false
	upgrade_chosen.emit(id)

# Czysta funkcja: 3 unikalne opcje z puli, deterministycznie wg seeda (tasowanie Fisher-Yates).
static func pick_three(pool: Array[String], rng_seed: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var copy: Array[String] = pool.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy.slice(0, 3)
