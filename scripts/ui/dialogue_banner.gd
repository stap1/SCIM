class_name DialogueBanner
extends CanvasLayer

# Dolny pasek dialogow Santiago. NIE pauzuje gry. Reaguje na sygnaly GameState
# (enemy_killed, boss_incoming), dobiera kwestie z NarrativeData i pokazuje je z efektem
# maszyny do pisania (B6). Kolejka FIFO - przy gestej walce kwestie nie nakladaja sie:
# nowa czeka, az poprzednia zostanie napisana, przetrzymana (DIALOGUE_HOLD) i wygaszona.

@onready var panel: Control = get_node_or_null("Panel")
@onready var typer: TypewriterLabel = get_node_or_null("Panel/Line")

var _queue: Array[String] = []
var _busy: bool = false
# Ostatni osiagniety prog meduz - kwestia progu leci dokladnie raz.
var _last_jelly: int = 0

func _ready() -> void:
	if panel:
		panel.modulate.a = 0.0
	GameState.enemy_killed.connect(_on_enemy_killed)
	GameState.boss_incoming.connect(_on_boss_incoming)
	if typer:
		typer.finished.connect(_on_typing_finished)

func _on_enemy_killed(type: int, count: int) -> void:
	var r := resolve_kill_line(type, count, _last_jelly)
	_last_jelly = int(r["last_jelly"])
	var line: String = r["line"]
	if not line.is_empty():
		enqueue(line)

func _on_boss_incoming() -> void:
	enqueue(NarrativeData.BOSS_INCOMING)

func enqueue(line: String) -> void:
	_queue.append(line)
	if not _busy:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var line: String = _queue.pop_front()
	if panel:
		var t := create_tween()
		t.tween_property(panel, "modulate:a", 1.0, GameConfig.DIALOGUE_FADE)
	if typer:
		typer.start(line)
	else:
		_on_typing_finished()  # brak komponentu - traktuj jak natychmiast napisane

func _on_typing_finished() -> void:
	await get_tree().create_timer(GameConfig.DIALOGUE_HOLD).timeout
	if panel:
		var t := create_tween()
		t.tween_property(panel, "modulate:a", 0.0, GameConfig.DIALOGUE_FADE)
		await t.finished
	_show_next()

# Czysta funkcja: kwestia dla zabicia (type,count) wzgledem ostatniego progu meduz.
# Zwraca {"line": String, "last_jelly": int}. Pusty "line" -> brak kwestii.
# Pierwsza barakuda/rekin (count==1) i kolejne progi meduz (10/30/60) - kazdy raz.
static func resolve_kill_line(type: int, count: int, last_jelly: int) -> Dictionary:
	if type == Enemy.EnemyType.BARRACUDA and count == 1:
		return {"line": NarrativeData.FIRST_BARRACUDA, "last_jelly": last_jelly}
	if type == Enemy.EnemyType.SHARK and count == 1:
		return {"line": NarrativeData.FIRST_SHARK, "last_jelly": last_jelly}
	if type == Enemy.EnemyType.JELLYFISH:
		var thr := highest_jelly_threshold(count)
		if thr > last_jelly:
			return {"line": NarrativeData.jellyfish_line_for(count), "last_jelly": thr}
	return {"line": "", "last_jelly": last_jelly}

# Czysta funkcja: najwyzszy prog meduz <= count (lub -1, gdy zaden nieosiagniety).
static func highest_jelly_threshold(count: int) -> int:
	var best := -1
	for k in NarrativeData.JELLYFISH_LINES:
		if int(k) <= count and int(k) > best:
			best = int(k)
	return best
