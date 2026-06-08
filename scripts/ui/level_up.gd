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

func _on_level_up(new_level: int) -> void:
	# Co MILESTONE_LEVEL_INTERVAL poziomow: specjalny power-up ZAMIAST zwyklej karty.
	if is_milestone_level(new_level, GameConfig.MILESTONE_LEVEL_INTERVAL):
		_current_ids = Upgrades.milestone_ids()
	else:
		_current_ids = pick_three(_upgrade_pool(), randi())
		# Wszystkie ulepszenia wyczerpane (max_level) - nie pauzuj, by nie zablokowac gry.
		if _current_ids.is_empty():
			return
	for i in cards.size():
		var card = cards[i]
		if card == null:
			continue
		if i < _current_ids.size():
			card.show()
			_set_card_text(card, _current_ids[i])
		else:
			card.hide()
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

# Pula id ulepszen jeszcze niewyczerpanych (Upgrades pilnuje max_level).
func _upgrade_pool() -> Array[String]:
	return Upgrades.available_ids()

func _set_card_text(card: Node, id: String) -> void:
	var text := id
	# info() obejmuje ulepszenia zwykle i milestone.
	var u := Upgrades.info(id)
	if not u.is_empty():
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

# Czysta funkcja: czy dany poziom jest "milestone" (co interval -> ekran specjalny).
static func is_milestone_level(level: int, interval: int) -> bool:
	return interval > 0 and level > 0 and level % interval == 0

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
