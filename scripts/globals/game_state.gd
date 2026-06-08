extends Node

# GameState - JEDYNE zrodlo prawdy o stanie sesji (time, score, level, xp, health).
# Tylko on inkrementuje czas i score. Inne wezly wylacznie czytaja i sluchaja sygnalow.

# --- Sygnaly ---
signal health_changed(new_health: float)
signal score_changed(new_score: int)
signal time_changed(new_time: float)
signal xp_changed(new_xp: int)
signal level_up(new_level: int)
# Ostrzezenie przed pojawieniem sie mini-bossa.
signal boss_incoming
# Emitowany DOKLADNIE RAZ, gdy gra sie konczy (guard w trigger_game_over).
signal game_over

# --- Wartosci startowe (uzywane przez reset) ---
const START_HEALTH: float = 100.0

# --- Stan sesji ---
var time: float = 0.0
var score: int = 0
var level: int = 1
var xp: int = 0
var health: float = 100.0
var max_health: float = 100.0

# --- Pola pomocnicze uzywane przez pozostale systemy gry ---
var xp_to_next: int = 0
# Mnoznik zasiegu zbierania XP (upgrade resource_magnet). Czytany przez XpOrb na spawnie.
var magnet_range_mult: float = 1.0
# Dlugosc sesji w minutach (ustawienie gracza, ladowane z configu - nie resetowane).
var session_length: int = 15
# Accessibility (ustawienia gracza) - czytane przez kod efektow (shake/flash).
var reduce_shake: bool = false
var reduce_flashing: bool = false
var eco_score: int = 0
var enemies_killed: int = 0
var miniboss_defeated: bool = false
var is_paused: bool = false
var is_game_over: bool = false

# --- Mutatory: jedyne dozwolone sciezki zmiany stanu ---

func reset() -> void:
	time = 0.0
	score = 0
	level = 1
	xp = 0
	max_health = START_HEALTH
	health = max_health
	enemies_killed = 0
	miniboss_defeated = false
	magnet_range_mult = 1.0
	is_paused = false
	is_game_over = false
	health_changed.emit(health)
	score_changed.emit(score)
	time_changed.emit(time)

func add_time(delta: float) -> void:
	time += delta
	time_changed.emit(time)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

# Wymuszony awans (nagroda za pokonanie bossa) - zwieksza poziom i emituje level_up.
func grant_level_up() -> void:
	level += 1
	level_up.emit(level)

func add_xp(amount: int) -> void:
	xp += amount
	# Wiele awansow naraz: while (nie if) - duza wartosc nie gubi poziomow.
	while xp >= xp_threshold(level):
		xp -= xp_threshold(level)
		level += 1
		level_up.emit(level)
	xp_to_next = xp_threshold(level)
	xp_changed.emit(xp)

# Czysta funkcja: ile XP potrzeba na dany poziom. Wzor: level*10 + (level-1)^2 * 5.
static func xp_threshold(level_value: int) -> int:
	return level_value * 10 + (level_value - 1) * (level_value - 1) * 5

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	health_changed.emit(health)
	if health <= 0.0:
		trigger_game_over()

# Jedyne miejsce konczenia gry. Guard gwarantuje, ze sygnal game_over poleci dokladnie raz.
func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over.emit()
