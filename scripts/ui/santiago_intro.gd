class_name SantiagoIntro
extends CanvasLayer

# Intro nowej gry: overlay (PROCESS_MODE_ALWAYS) pokazuje LOSOWY portret Santiago,
# odlicza 3-2-1, na koniec gra syrene portowa i odslania rozgrywke. Wejscie i wyjscie
# animowane jak przewracana strona komiksu/ksiazki (page-turn).
#
# PAUZA: get_tree().paused = true trzyma cala gre (Main jest pausable, wiec jego _process
# i GameState.add_time stoja - czas gry NIE rosnie przez intro). Overlay jest ALWAYS, wiec
# jego Tween/odliczanie graja mimo pauzy. Pauza zdejmowana DOPIERO po animacji wyjscia.

signal intro_finished

@onready var bg: ColorRect = get_node_or_null("Bg")
@onready var page: Control = get_node_or_null("Page")
@onready var portrait: TextureRect = get_node_or_null("Page/Portrait")
@onready var countdown_label: Label = get_node_or_null("Page/Countdown")

var _finished: bool = false
# Redukcja migotania (dostepnosc): bez efektownego obracania strony - lagodny fade.
var _reduce: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_random_portrait()
	_start_intro()

# --- Losowanie portretu ---
func _load_random_portrait() -> void:
	var paths := _available_portraits()
	var idx := pick_portrait_index(paths.size(), randi())
	if idx >= 0 and portrait:
		portrait.texture = load(paths[idx])

# Portrety realnie istniejace (assety opcjonalne - brak pliku nie crashuje).
static func _available_portraits() -> Array[String]:
	var out: Array[String] = []
	for p in NarrativeData.SANTIAGO_PORTRAITS:
		if ResourceLoader.exists(p):
			out.append(p)
	return out

# Czysta funkcja: indeks losowego portretu (lub -1 gdy pula pusta), deterministycznie wg seeda.
static func pick_portrait_index(count: int, rng_seed: int) -> int:
	if count <= 0:
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	return rng.randi_range(0, count - 1)

# --- Sekwencja intro (JEDEN Tween, gra mimo pauzy bo overlay = ALWAYS) ---
# Animacje tokenow sa CZESCIA glownego tweena (bez zagniezdzania create_tween w callbackach -
# wczesniej zagniezdzone tweeny tej samej etykiety kolidowaly i odliczanie utykalo na "3").
func _start_intro() -> void:
	get_tree().paused = true
	_reduce = not SettingsStore.should_flash(SettingsStore.reduce_flashing)
	_set_page(0.0)
	if countdown_label:
		countdown_label.modulate.a = 0.0
	var step: float = GameConfig.INTRO_COUNTDOWN_STEP
	var tw := create_tween()
	# Wejscie: przewrocenie strony odslania portret.
	tw.tween_method(_set_page, 0.0, 1.0, GameConfig.INTRO_PAGE_TURN_TIME)
	# Odliczanie: kazdy token (3,2,1, okrzyk) pojawia sie duzy i kurczac sie znika.
	if countdown_label != null:
		for token in ["3", "2", "1", NarrativeData.INTRO_SHOUT]:
			tw.tween_callback(_prep_token.bind(token))
			if _reduce:
				tw.tween_property(countdown_label, "modulate:a", 0.0, step)
			else:
				tw.tween_property(countdown_label, "scale", Vector2(0.5, 0.5), step).set_trans(Tween.TRANS_QUAD)
				tw.parallel().tween_property(countdown_label, "modulate:a", 0.0, step)
	else:
		tw.tween_interval(step * 4.0)  # zachowaj rytm gdy brak etykiety
	# Przejscie na wode: syrena + przewrocenie strony odslaniajace rozgrywke.
	tw.tween_callback(func() -> void: AudioManager.play_sfx("port_siren"))
	tw.tween_method(_set_page_out, 0.0, 1.0, GameConfig.INTRO_PAGE_TURN_TIME)
	tw.tween_callback(_finish)

# Ustawia token odliczania na stan poczatkowy (duzy, pelna widocznosc). Animacje robi glowny tween.
func _prep_token(text_value: String) -> void:
	if countdown_label == null:
		return
	countdown_label.text = text_value
	countdown_label.pivot_offset = countdown_label.size * 0.5
	countdown_label.modulate.a = 1.0
	countdown_label.scale = Vector2.ONE if _reduce else Vector2(1.6, 1.6)

# Page-turn IN (0->1): strona "kladzie sie" od grzbietu (lewa krawedz).
func _set_page(t: float) -> void:
	if page == null:
		return
	page.pivot_offset = Vector2(0.0, page.size.y * 0.5)
	if _reduce:
		page.scale = Vector2.ONE
		page.modulate.a = t
	else:
		page.scale = Vector2(t, 1.0)
		page.modulate.a = clampf(t * 2.0, 0.0, 1.0)

# Page-turn OUT (0->1): strona odchyla sie i ciemne tlo gasnie, odslaniajac gre.
func _set_page_out(t: float) -> void:
	if bg:
		bg.color.a = 1.0 - t
	if page == null:
		return
	page.pivot_offset = Vector2(0.0, page.size.y * 0.5)
	if _reduce:
		page.modulate.a = 1.0 - t
	else:
		page.scale = Vector2(1.0 - t, 1.0)
		page.modulate.a = 1.0 - clampf(t * 1.5, 0.0, 1.0)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	get_tree().paused = false
	_trigger_first_line()
	intro_finished.emit()
	queue_free()

# Po zdjeciu pauzy: pierwsza kwestia protagonisty W GRZE (z maszyna do pisania).
# Luzne powiazanie - baner przez grupe, bez twardej sciezki.
func _trigger_first_line() -> void:
	var db := get_tree().get_first_node_in_group("dialogue_banner")
	if db != null and db.has_method("play_first_line"):
		db.play_first_line()

# Bezpiecznik: jesli overlay znika przed koncem intro (zmiana sceny / restart / test),
# nie zostawiaj gry zapauzowanej.
func _exit_tree() -> void:
	if not _finished and get_tree() != null:
		get_tree().paused = false
