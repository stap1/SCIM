extends CanvasLayer

# Ekran wyboru ulepszenia. Na sygnal GameState.level_up pauzuje gre i pokazuje 3 karty.
# process_mode = ALWAYS (w .tscn), by przyciski dzialaly mimo get_tree().paused.
# Realne efekty ulepszen dochodza w kroku 15 (Upgrades) - tu emitujemy tylko upgrade_chosen(id).

signal upgrade_chosen(id: String)

const Accessibility := preload("res://scripts/ui/settings.gd")

@onready var panel: Control = $Panel
@onready var cards: Array = [$Panel/Card0, $Panel/Card1, $Panel/Card2]

var _current_ids: Array[String] = []

func _ready() -> void:
	if panel:
		panel.hide()
	GameState.level_up.connect(_on_level_up)
	# Wybor karty naklada realny efekt ulepszenia (autoload Upgrades).
	upgrade_chosen.connect(Upgrades.apply)
	for i in cards.size():
		var card = cards[i]
		if card:
			card.pressed.connect(_on_card_pressed.bind(i))

func _on_level_up(_new_level: int) -> void:
	_current_ids = pick_three(_upgrade_pool(), randi())
	for i in cards.size():
		if cards[i] and i < _current_ids.size():
			_set_card_text(cards[i], _current_ids[i])
	if panel:
		panel.show()
	get_tree().paused = true
	_flash()

# Krotki rozblysk przy awansie - pomijany gdy accessibility "reduce flashing" wlaczone.
func _flash() -> void:
	var flash := get_node_or_null("Flash")
	if flash == null:
		return
	if not Accessibility.should_flash(GameState.reduce_flashing):
		return
	flash.color = Color(1, 1, 1, 0.7)
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.0, 0.4)

# Pula id ulepszen z jedynego zrodla (autoload Upgrades).
func _upgrade_pool() -> Array[String]:
	var pool: Array[String] = []
	for id in Upgrades.UPGRADES:
		pool.append(id)
	return pool

func _set_card_text(card: Node, id: String) -> void:
	var text := id
	if Upgrades.UPGRADES.has(id):
		var u = Upgrades.UPGRADES[id]
		text = str(u.get("name", id)) + "\n" + str(u.get("description", ""))
	var label = card.get_node_or_null("Label")
	if label:
		label.text = text
	else:
		card.text = text

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
