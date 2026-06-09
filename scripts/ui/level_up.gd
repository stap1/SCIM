extends CanvasLayer

# Ekran wyboru ulepszenia. Na sygnal GameState.level_up pauzuje gre i pokazuje 3 karty.
# process_mode = ALWAYS (w .tscn), by przyciski dzialaly mimo get_tree().paused.
# Realne efekty ulepszen dochodza w kroku 15 (Upgrades) - tu emitujemy tylko upgrade_chosen(id).

signal upgrade_chosen(id: String)

## Ile kart pokazac na ekranie zwyklym i milestone (stale - bez magic numbers).
const REGULAR_CHOICES: int = 3
const MILESTONE_CHOICES: int = 3

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
	_current_ids = _roll_choices(new_level)
	# JEDNO wspolne zabezpieczenie anty-softlock dla obu typow level-upu: pusta oferta
	# (wszystko wyczerpane) - nie pauzuj, by nie zablokowac gry.
	if _current_ids.is_empty():
		return
	_present_cards()
	if panel:
		panel.show()
	get_tree().paused = true
	_flash()

## Dobiera oferte kart dla danego poziomu. Na poziomach milestone (co
## GameConfig.MILESTONE_LEVEL_INTERVAL) zwraca WYLACZNIE pule milestone, w przeciwnym
## razie WYLACZNIE pule zwykla. Pule pochodza z rozlacznych katalogow Upgrades - to
## strukturalnie gwarantuje, ze specjalne ulepszenia nie trafia do zwyklego losowania.
func _roll_choices(level: int) -> Array[String]:
	if is_milestone_level(level, GameConfig.MILESTONE_LEVEL_INTERVAL):
		return pick_n(Upgrades.milestone_ids(), randi(), MILESTONE_CHOICES)
	return pick_n(Upgrades.available_ids(), randi(), REGULAR_CHOICES)

## Pokazuje karty dla biezacych _current_ids; nadmiarowe karty chowa.
func _present_cards() -> void:
	for i in cards.size():
		var card = cards[i]
		if card == null:
			continue
		if i < _current_ids.size():
			card.show()
			_set_card_text(card, _current_ids[i])
		else:
			card.hide()

# Krotki rozblysk przy awansie - pomijany gdy accessibility "reduce flashing" wlaczone.
func _flash() -> void:
	var flash := get_node_or_null("Flash")
	if flash == null:
		return
	if not SettingsStore.should_flash(SettingsStore.reduce_flashing):
		return
	flash.color = Color(1, 1, 1, 0.7)
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.0, 0.4)

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

# Czysta funkcja: count unikalnych opcji z puli, deterministycznie wg seeda
# (tasowanie Fisher-Yates). Mniej niz count, gdy pula krotsza.
static func pick_n(pool: Array[String], rng_seed: int, count: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var copy: Array[String] = pool.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy.slice(0, count)
