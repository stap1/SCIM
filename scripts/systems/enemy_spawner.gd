extends Node

# Spawner wrogow. Trudnosc rosnie z czasem wg difficulty_curve (DANE, nie kod):
# klucz = minuta, wartosc = {enemies: [typy], spawn_interval}. Co tick spawner odczytuje
# aktualny tier (current_tier), dostosowuje interval Timera i losuje typ z dozwolonej listy.
# Wszystkie typy uzywaja enemy.gd (jedna baza).

@export var max_enemies: int = GameConfig.ENEMY_MAX_COUNT

const JellyfishScene := preload("res://scenes/enemies/enemy.tscn")
const BarracudaScene := preload("res://scenes/enemies/barracuda.tscn")
const SharkScene := preload("res://scenes/enemies/shark.tscn")
const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")
const DeathBurstScene := preload("res://scenes/death_burst.tscn")
const XpOrbScene := preload("res://scenes/xp_orb.tscn")
const HealPlankScene := preload("res://scenes/heal_plank.tscn")

var _boss_warned: bool = false
var _boss_spawned: bool = false
# Waga per scena wroga (zbudowana w _ready z GameConfig.ENEMY_WEIGHT). Do wazonego losowania.
var _weight_by_scene: Dictionary = {}
# Dodatek do budzetu wrogow z meta-progresji "horda" (R3d ustawi z MetaProgress; tu 0 = brak).
# Wiecej wrogow naraz = wiecej zabic = wiecej punktow (risk/reward).
var _spawn_budget_bonus: float = 0.0
# Mapa typ (Enemy.EnemyType int) -> scena, do eventow spawnu.
var _scene_for_type: Dictionary = {}
# Stan eventow: id -> czy juz odpalil (jednorazowe); osobno liczba odpalen eventow czasowych.
var _event_fired: Dictionary = {}
var _time_event_count: Dictionary = {}

# --- Eventy spawnu (powtarzalne, DANE) ---
# Zmienne charakterystyki: typ wroga (spawn) + trigger + tryb. Latwo dodac/usunac/zmienic.
#  trigger.kind: "kill_count" (na sygnal enemy_killed danego typu) lub "time" (czas sesji).
#  trigger.type: typ liczonego wroga (tylko kill_count). trigger.at: prog/czas. trigger.repeat: bool.
#  mode: "fill" (zapelnij budzet danym typem) lub "burst" (count sztuk).
const SPAWN_EVENTS := [
	# "Morze nie znosi pustki" - po 30. zabitej meduzie rojenie meduz zapelnia budzet.
	{"id": "jelly_swarm", "type": 0, "mode": "fill",
		"trigger": {"kind": "kill_count", "type": 0, "at": 30, "repeat": false}},
	# Cykliczny rajd barakud co 100 s (inny typ + inny trigger + powtarzalny - demonstruje system).
	{"id": "barracuda_raid", "type": 1, "mode": "burst", "count": 4,
		"trigger": {"kind": "time", "at": 100.0, "repeat": true}},
]

# Balans edytowalny w jednym miejscu - bez dotykania logiki.
var difficulty_curve := {
	0: {"enemies": [JellyfishScene], "spawn_interval": 1.2},
	1: {"enemies": [JellyfishScene, BarracudaScene], "spawn_interval": 1.0},
	2: {"enemies": [JellyfishScene, BarracudaScene, SharkScene], "spawn_interval": 0.8},
	3: {"enemies": [JellyfishScene, BarracudaScene, SharkScene], "spawn_interval": 0.6},
}

var _timer: Timer
var _heal_timer: Timer

func _ready() -> void:
	# Mapa scena -> waga (z GameConfig.ENEMY_WEIGHT per typ).
	_weight_by_scene = {
		JellyfishScene: int(GameConfig.ENEMY_WEIGHT[0]),
		BarracudaScene: int(GameConfig.ENEMY_WEIGHT[1]),
		SharkScene: int(GameConfig.ENEMY_WEIGHT[2]),
	}
	_scene_for_type = {0: JellyfishScene, 1: BarracudaScene, 2: SharkScene}
	# Eventy spawnu na zabiciach danego typu (np. rojenie meduz przy "Morze nie znosi pustki").
	GameState.enemy_killed.connect(_on_event_kill)
	# _spawn_budget_bonus zwieksza budzet wg meta-progresji "horda" - podpinane w R3d.

	_timer = Timer.new()
	_timer.wait_time = difficulty_curve[0]["spawn_interval"]
	_timer.autostart = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)

	# Osobny timer leczniczych desek (co HEAL_PLANK_INTERVAL, po karencji startowej).
	_heal_timer = Timer.new()
	_heal_timer.wait_time = GameConfig.HEAL_PLANK_INTERVAL
	_heal_timer.autostart = true
	_heal_timer.timeout.connect(_on_heal_timeout)
	add_child(_heal_timer)

# Wstrzymuje spawn wrogow i desek (laska na zebranie orbow po wygranej, R4a).
func stop_spawning() -> void:
	if _timer:
		_timer.stop()
	if _heal_timer:
		_heal_timer.stop()

# --- Eventy spawnu (powtarzalne, dane: typ wroga + trigger) ---

# Trigger na zabiciu: eventy kill_count na sygnal enemy_killed danego typu.
func _on_event_kill(killed_type: int, count: int) -> void:
	if GameState.is_game_over or GameState.victory_locked:
		return
	for ev in SPAWN_EVENTS:
		var t: Dictionary = ev["trigger"]
		if t.get("kind", "") != "kill_count":
			continue
		if int(t.get("type", -1)) != killed_type:
			continue
		var repeat := bool(t.get("repeat", false))
		if not event_kill_triggered(int(t.get("at", 0)), repeat, count):
			continue
		if not repeat:
			if bool(_event_fired.get(ev["id"], false)):
				continue
			_event_fired[ev["id"]] = true
		_run_event(ev)

# Trigger czasowy: sprawdzany co tick. repeat -> co 'at' sekund; inaczej raz po 'at'.
func _check_time_events() -> void:
	if GameState.is_game_over or GameState.victory_locked:
		return
	for ev in SPAWN_EVENTS:
		var t: Dictionary = ev["trigger"]
		if t.get("kind", "") != "time":
			continue
		var at := float(t.get("at", 0.0))
		if at <= 0.0:
			continue
		if bool(t.get("repeat", false)):
			var due := int(floor(GameState.time / at))
			if due > int(_time_event_count.get(ev["id"], 0)):
				_time_event_count[ev["id"]] = due
				_run_event(ev)
		elif GameState.time >= at and not bool(_event_fired.get(ev["id"], false)):
			_event_fired[ev["id"]] = true
			_run_event(ev)

# Wykonuje event: zapelnia budzet danym typem (fill) lub spawnuje 'count' sztuk (burst).
func _run_event(ev: Dictionary) -> void:
	var enemy_type := int(ev.get("type", 0))
	var scene = _scene_for_type.get(enemy_type, null)
	if scene == null:
		return
	if ev.get("mode", "fill") == "burst":
		_burst_spawn(scene, int(ev.get("count", 1)))
	else:
		_fill_budget_with(scene, enemy_type)

# Spawnuje wrogow danego typu az do zapelnienia budzetu wagi (lub twardego capu liczby).
func _fill_budget_with(scene: PackedScene, enemy_type: int) -> void:
	var w := int(GameConfig.ENEMY_WEIGHT.get(enemy_type, 1))
	var budget := weight_budget(GameState.time, _spawn_budget_bonus)
	var guard := 0
	while guard < max_enemies:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.size() >= max_enemies:
			break
		if float(current_enemy_weight(enemies) + w) > budget:
			break
		spawn_enemy(scene)
		guard += 1

# Spawnuje do 'n' wrogow danego typu (respektuje twardy cap liczby).
func _burst_spawn(scene: PackedScene, n: int) -> void:
	for i in n:
		if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
			break
		spawn_enemy(scene)

# Czysta funkcja: czy event kill_count ma sie odpalic. repeat -> co 'at' zabic; inaczej raz przy 'at'.
static func event_kill_triggered(at: int, repeat: bool, count: int) -> bool:
	if at <= 0:
		return false
	if repeat:
		return count % at == 0
	return count == at

func _on_timeout() -> void:
	if GameState.is_paused or GameState.is_game_over:
		return

	_check_boss()
	_check_time_events()

	# Karencja startowa - brak zwyklych wrogow przez pierwsze SPAWN_GRACE_SECONDS.
	if is_in_grace(GameState.time, GameConfig.SPAWN_GRACE_SECONDS):
		return

	var enemies := get_tree().get_nodes_in_group("enemies")
	# Twardy cap liczby (ochrona FPS/Web) - niezalezny od budzetu wagi.
	if enemies.size() >= max_enemies:
		return

	var tier := current_tier(GameState.time, _curve_keys())
	var entry: Dictionary = difficulty_curve[tier]
	# Interwal spawnu skraca sie z czasem (wieksza czestotliwosc fal).
	_timer.wait_time = spawn_interval_for(GameState.time, entry["spawn_interval"])

	var allowed: Array = entry["enemies"]
	if allowed.is_empty():
		return

	# Wazone losowanie typu (silniejsi rzadziej) sposrod dozwolonych w tierze.
	var weights: Array[int] = []
	for scene in allowed:
		weights.append(int(_weight_by_scene.get(scene, 1)))
	var idx := weighted_pick(weights, randf())
	if idx == -1:
		return
	var picked: PackedScene = allowed[idx]
	var w_pick := int(_weight_by_scene.get(picked, 1))

	# Budzet wagi na ekranie rosnie z czasem - to progresywnie zwieksza liczbe wrogow.
	var budget := weight_budget(GameState.time, _spawn_budget_bonus)
	var on_screen := current_enemy_weight(enemies)
	if float(on_screen + w_pick) > budget:
		return  # budzet wyczerpany w tym ticku
	spawn_enemy(picked)

# Suma wag zywych zwyklych wrogow na ekranie (boss nie ma enemy_type - poza budzetem).
func current_enemy_weight(enemies: Array) -> int:
	var total := 0
	for e in enemies:
		if is_instance_valid(e) and "enemy_type" in e:
			total += int(GameConfig.ENEMY_WEIGHT.get(e.enemy_type, 1))
	return total

# Czysta funkcja: budzet wagi na ekranie dla danego czasu. bonus (meta "horda") dodaje
# wrogow PONAD bazowy cap (wiecej wrogow = wiecej punktow).
static func weight_budget(time_seconds: float, bonus: float) -> float:
	var b := GameConfig.ENEMY_WEIGHT_BUDGET_BASE + GameConfig.ENEMY_WEIGHT_BUDGET_PER_MIN * (time_seconds / 60.0)
	b = clampf(b, GameConfig.ENEMY_WEIGHT_BUDGET_BASE, GameConfig.ENEMY_WEIGHT_BUDGET_MAX)
	return b + maxf(0.0, bonus)

# Czysta funkcja: indeks wybrany wg wag i rng_value w [0,1). Pusta/zerowa suma -> -1.
static func weighted_pick(weights: Array[int], rng_value: float) -> int:
	var total := 0
	for w in weights:
		total += w
	if total <= 0:
		return -1
	var r := clampf(rng_value, 0.0, 0.999999) * float(total)
	var acc := 0.0
	for i in weights.size():
		acc += float(weights[i])
		if r < acc:
			return i
	return weights.size() - 1

# Czysta funkcja: interwal spawnu skrocony wg czasu (mnoznik capowany do MIN_FACTOR).
static func spawn_interval_for(time_seconds: float, base: float) -> float:
	var factor := clampf(1.0 - (time_seconds / 60.0) * GameConfig.SPAWN_INTERVAL_RAMP,
		GameConfig.SPAWN_INTERVAL_MIN_FACTOR, 1.0)
	return base * factor

func _curve_keys() -> Array[int]:
	var keys: Array[int] = []
	for k in difficulty_curve:
		keys.append(k)
	return keys

func spawn_enemy(scene: PackedScene) -> Node:
	var player := get_tree().get_first_node_in_group("player")
	var vp_size := get_viewport().get_visible_rect().size
	var pos := spawn_position_for_edge(randi() % 4, vp_size)

	# Spawn wzgledem widoku gracza (kamera sledzi lodz).
	if player != null:
		pos += player.global_position - vp_size / 2.0

	var enemy := scene.instantiate()
	# Pozycja PRZED add_child: inaczej przez 1 klatke fizyki wrog jest w lokalnym (0,0) =
	# pozycja Main (~lodz), co daje falszywe nalozenie na Hurtbox i natychmiastowy cios (bug #1).
	enemy.position = get_parent().to_local(pos)
	get_parent().add_child(enemy)
	if player != null and enemy.has_method("set_target"):
		enemy.set_target(player)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	return enemy

func _on_enemy_died(pos: Vector2, xp_value: int, type: int) -> void:
	AudioManager.play_sfx("enemy_death")
	GameState.register_kill(type)  # licznik per typ + sygnal narracji (B1)
	var burst := DeathBurstScene.instantiate()
	get_parent().add_child(burst)
	burst.global_position = pos

	# Model 1 orb = 1 XP, zrzut x2 (R5b): wrog wart xp_value zrzuca 2*xp_value orbow po 1 XP.
	_spawn_orbs(pos, xp_value * GameConfig.XP_ORB_DROP_MULT, 1)

# Spawnuje 'count' orbow po 'value_each' XP, rozrzuconych w promieniu wokol center.
# Cap (XP_ORB_MAX_ON_SCREEN) chroni FPS: nadmiar oddaje XP wprost, nie tworzac wezla.
func _spawn_orbs(center: Vector2, count: int, value_each: int) -> void:
	for i in count:
		if _orb_count() >= GameConfig.XP_ORB_MAX_ON_SCREEN:
			GameState.add_xp(value_each)
			continue
		var orb := XpOrbScene.instantiate()
		orb.xp_value = value_each  # przed add_child (gruby orb skaluje sie w _ready)
		var angle := randf() * TAU
		var radius := sqrt(randf()) * GameConfig.XP_ORB_SCATTER_RADIUS
		# Pozycja przed add_child - inaczej orb przez klatke jest w origin (~lodz) i moglby
		# zostac od razu zebrany.
		orb.position = get_parent().to_local(center + Vector2(radius, 0.0).rotated(angle))
		get_parent().add_child(orb)

func _orb_count() -> int:
	return get_tree().get_nodes_in_group("xp_orbs").size()

# --- Lecznicze deski ---

func _on_heal_timeout() -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	if is_in_grace(GameState.time, GameConfig.SPAWN_GRACE_SECONDS):
		return
	_spawn_heal_plank()

func _spawn_heal_plank() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	# W zasiegu gracza (catchable): losowy kierunek, 200-400 px od lodzi.
	var angle := randf() * TAU
	var dist := randf_range(200.0, 400.0)
	var plank := HealPlankScene.instantiate()
	plank.position = get_parent().to_local(player.global_position + Vector2(dist, 0.0).rotated(angle))
	get_parent().add_child(plank)

# --- Mini-boss ---

# Czysta funkcja: czy trwa karencja startowa (brak zwyklych wrogow).
static func is_in_grace(time: float, grace: float) -> bool:
	return time < grace

# Czysta funkcja: czas na bossa (dokladnie raz po MINIBOSS_SPAWN_TIME).
static func should_spawn_boss(time: float, already_spawned: bool) -> bool:
	return time >= GameConfig.MINIBOSS_SPAWN_TIME and not already_spawned

func _check_boss() -> void:
	if not _boss_warned and GameState.time >= GameConfig.MINIBOSS_SPAWN_TIME - GameConfig.MINIBOSS_WARNING:
		_boss_warned = true
		GameState.boss_incoming.emit()
	if should_spawn_boss(GameState.time, _boss_spawned):
		_boss_spawned = true
		_spawn_boss()

func _spawn_boss() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var boss := MotorBoatScene.instantiate()
	if player != null:
		boss.position = get_parent().to_local(player.global_position + Vector2(0, -350))
	get_parent().add_child(boss)
	if player != null:
		if boss.has_method("set_target"):
			boss.set_target(player)
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated(pos: Vector2) -> void:
	GameState.miniboss_defeated = true
	GameState.register_kill(Enemy.EnemyType.MINIBOSS)  # boss liczony per typ (B1)
	AudioManager.play_sfx("enemy_death")
	var burst := DeathBurstScene.instantiate()
	get_parent().add_child(burst)
	burst.global_position = pos

	# Boss zrzuca grube orby (hybryda count x value), liczba x2 (R5b), oprocz awansu nizej.
	_spawn_orbs(pos, GameConfig.XP_ORB_BOSS_COUNT * GameConfig.XP_ORB_DROP_MULT, GameConfig.XP_ORB_BOSS_VALUE)

	# Gwarantowany awans (nagroda) - pokazuje ekran wyboru ulepszenia.
	GameState.grant_level_up()

# Czysta funkcja: najwyzszy klucz krzywej <= aktualnej minucie (floor(time/60)).
static func current_tier(time_seconds: float, curve_keys: Array[int]) -> int:
	var minute := int(floor(time_seconds / 60.0))
	var best := -1
	for k in curve_keys:
		if k <= minute and k > best:
			best = k
	if best == -1 and not curve_keys.is_empty():
		best = curve_keys.min()
	return best

# Czysta funkcja (bez zaleznosci od drzewa): pozycja tuz poza prostokatem widoku.
# edge: 0=gora, 1=prawo, 2=dol, 3=lewo. Zawsze zwraca punkt poza [0, viewport_size].
static func spawn_position_for_edge(edge: int, viewport_size: Vector2) -> Vector2:
	var margin := 50.0
	match edge:
		0:
			return Vector2(randf_range(0.0, viewport_size.x), -margin)
		1:
			return Vector2(viewport_size.x + margin, randf_range(0.0, viewport_size.y))
		2:
			return Vector2(randf_range(0.0, viewport_size.x), viewport_size.y + margin)
		_:
			return Vector2(-margin, randf_range(0.0, viewport_size.y))
