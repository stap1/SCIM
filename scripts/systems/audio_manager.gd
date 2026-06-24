extends Node

const SFX_PATHS := {
	"harpoon_shot": "res://audio/sfx/harpoon_shot.ogg",
	"hit": "res://audio/sfx/hit.ogg",
	"enemy_death": "res://audio/sfx/enemy_death.wav",
	"boss_spawn": "res://audio/sfx/boss_spawn.ogg",
	"player_hit": "res://audio/sfx/player_hit.ogg",
	"level_up": "res://audio/sfx/level_up.ogg",
	"ui_click": "res://audio/sfx/ui_click.ogg",
	"heal": "res://audio/sfx/heal.ogg",
	"heal_spawn": "res://audio/sfx/heal_spawn.ogg", 
	"xp_pickup": "res://audio/sfx/xp_pickup.ogg",
	"typewriter_key": "res://audio/sfx/typewriter_key.ogg",
	"typewriter_bell": "res://audio/sfx/typewriter_bell.ogg",
	"port_siren": "res://audio/sfx/port_siren.ogg",
}

const SFX_POOL_SIZE := 16

const MUSIC := {
	"menu": "res://audio/music/music_menu.ogg",
	"gameplay": "res://audio/music/music_game.ogg",
	"boss": "res://audio/music/music_boss.ogg",
	"gameover": "res://audio/music/music_gameover.ogg",
	"victory": "res://audio/music/music_victory.ogg"
}

const AMBIENT_PATH := "res://audio/ambient/ambient_sea.ogg"
const MUSIC_CROSSFADE := 1.5

# --- STROJENIE DZWIEKU XP (combo pitch + throttling) ---
# Po tylu ms ciszy combo resetuje sie do bazowego tonu.
const XP_COMBO_RESET_MS := 1000
# Dzwieki gestsze niz to sa tlumione (nie graja), by uniknac przesterowan.
const XP_THROTTLE_MS := 50
# Przyrost tonu przy stlumionym (niegranym) zbiorze.
const XP_THROTTLE_PITCH_STEP := 0.02
# Przyrost tonu przy zagranym zbiorze.
const XP_PLAY_PITCH_STEP := 0.05
# Gorny limit tonu combo.
const XP_PITCH_MAX := 1.5
# Zakres tonu (1.0 .. 1.0 + SPAN) mapowany na kompensacje glosnosci.
const XP_PITCH_SPAN := 0.5
# Docelowe tlumienie przy maksymalnym tonie (kompensacja wysokich czestotliwosci).
const XP_VOLUME_MIN_DB := -6.0

var _sfx_streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _typewriter_player: AudioStreamPlayer
var current_music_track: String = ""

# --- ZMIENNE DO NAKŁADKI MIKSERA ---
var _debug_layer: CanvasLayer = null
# Mikser F1 i jego zapis (ResourceSaver na res://) dzialaja TYLKO w buildach debug.
# W release/web res:// jest read-only, a dev-mikser nie moze trafic do gracza.
# Ustawiane w _ready z OS.has_feature("debug"); testy wstrzykuja wartosc.
var _dev_mixer_enabled: bool = false

# --- ZMIENNE DO TŁUMIKA XP ---
var _last_xp_time: int = 0
var _current_xp_pitch: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dev_mixer_enabled = OS.has_feature("debug")

	for sfx_name in SFX_PATHS:
		var path: String = SFX_PATHS[sfx_name]
		if path != "" and ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)
		else:
			_sfx_streams[sfx_name] = null

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _bus_or_master("SFX")
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_or_master("Music")
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = _bus_or_master("Ambient")
	add_child(_ambient_player)

	_typewriter_player = AudioStreamPlayer.new()
	_typewriter_player.bus = _bus_or_master("SFX")
	add_child(_typewriter_player)
	
	if ResourceLoader.exists(AMBIENT_PATH):
		_ambient_player.stream = load(AMBIENT_PATH)
		_ambient_player.volume_db = -15.0 

	GameState.level_up.connect(_on_level_up)
	GameState.game_over.connect(_on_game_over)
	GameState.boss_incoming.connect(_on_boss_incoming)
	GameState.session_reset.connect(_on_session_reset)
	
	await get_tree().process_frame
	play_music(MUSIC["menu"])

# Obsługa klawisza F1 do włączania i wyłączania mikseru na ekranie.
# Bramka: w buildach release/web (bez cechy "debug") mikser jest niedostepny.
func _unhandled_input(event: InputEvent) -> void:
	if not _dev_mixer_enabled:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if _debug_layer == null:
			_build_screen_mixer()
		else:
			_debug_layer.visible = !_debug_layer.visible

func _on_level_up(_new_level: int) -> void: play_sfx("level_up")
func _on_game_over() -> void:
	play_music(MUSIC["victory"] if GameState.won else MUSIC["gameover"])
func _on_boss_incoming() -> void: 
	play_sfx("boss_spawn")
	crossfade_to(MUSIC["boss"], MUSIC_CROSSFADE)
func _on_session_reset() -> void: play_music(MUSIC["gameplay"])

func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name): return
	var stream = _sfx_streams[sfx_name]
	if stream == null: return
	var player := _sfx_players[_sfx_index]
	
	if AudioServer.get_bus_index(sfx_name) != -1:
		player.bus = sfx_name 
	else:
		player.bus = _bus_or_master("SFX") 
	
	if sfx_name == "xp_pickup":
		var step := compute_xp_playback(Time.get_ticks_msec(), _last_xp_time, _current_xp_pitch)
		_current_xp_pitch = step["next_pitch"]
		_last_xp_time = step["next_last_ms"]
		if not step["play"]:
			return
		player.pitch_scale = step["pitch"]
		player.volume_db = step["volume_db"]
	else:
		player.pitch_scale = 1.0 
		player.volume_db = 0.0

	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.play()

func play_sfx_pitched(sfx_name: String, pitch: float) -> void:
	if not _sfx_streams.has(sfx_name): return
	var stream = _sfx_streams[sfx_name]
	if stream == null: return
	var player := _sfx_players[_sfx_index]
	
	if AudioServer.get_bus_index(sfx_name) != -1:
		player.bus = sfx_name
	else:
		player.bus = _bus_or_master("SFX")
	
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = maxf(0.01, pitch)
	player.play()

func play_typewriter_key(pitch: float) -> void:
	if _typewriter_player == null: return
	var stream = _sfx_streams.get("typewriter_key")
	if stream == null: return
		
	if AudioServer.get_bus_index("typewriter_key") != -1:
		_typewriter_player.bus = "typewriter_key"
	else:
		_typewriter_player.bus = _bus_or_master("SFX")
		
	_typewriter_player.stream = stream
	_typewriter_player.pitch_scale = maxf(0.01, pitch)
	_typewriter_player.play()

func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null

func play_music(track: String) -> void:
	if _music_player == null: return
	
	stop_music()
	current_music_track = track

	if track != "" and ResourceLoader.exists(track):
		_music_player.stream = load(track)
		
		var assigned_bus = "Music" 
		if track == MUSIC["menu"] and AudioServer.get_bus_index("music_menu") != -1:
			assigned_bus = "music_menu"
		elif track == MUSIC["gameplay"] and AudioServer.get_bus_index("music_game") != -1:
			assigned_bus = "music_game"
		elif track == MUSIC["boss"] and AudioServer.get_bus_index("music_boss") != -1:
			assigned_bus = "music_boss"
		elif track == MUSIC["gameover"] and AudioServer.get_bus_index("music_gameover") != -1:
			assigned_bus = "music_gameover"
		elif track == MUSIC["victory"] and AudioServer.get_bus_index("music_victory") != -1:
			assigned_bus = "music_victory"
		
		_music_player.bus = _bus_or_master(assigned_bus)
		_music_player.play()
	
	if _ambient_player != null and _ambient_player.stream != null:
		if track == MUSIC["menu"]:
			if not _ambient_player.playing: _ambient_player.play()
		else:
			if _ambient_player.playing: _ambient_player.stop()

func crossfade_to(track: String, duration: float) -> void:
	current_music_track = track
	if _music_player == null:
		play_music(track)
		return
	var half := maxf(duration, 0.0) * 0.5
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, half)
	tween.tween_callback(func() -> void: play_music(track))
	tween.tween_property(_music_player, "volume_db", 0.0, half)

func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) != -1 else "Master"

static func fade_volume_db(t: float, from_db: float, to_db: float) -> float:
	return from_db + (to_db - from_db) * t

# Czysta logika combo XP: bez zaleznosci od drzewa scen (pure function extraction).
# Na podstawie czasu teraz/ostatniego zagrania i biezacego tonu liczy, czy zagrac
# dzwiek, z jakim tonem i glosnoscia oraz jaki ma byc nastepny stan (ton + znacznik czasu).
#   - elapsed > XP_COMBO_RESET_MS  -> reset tonu do 1.0 (po ciszy combo wygasa),
#   - elapsed < XP_THROTTLE_MS     -> tlumienie: nie gramy, podbijamy ton, czas bez zmian,
#   - w przeciwnym razie           -> gramy z kompensacja glosnosci i podbijamy ton.
static func compute_xp_playback(now_ms: int, last_ms: int, current_pitch: float) -> Dictionary:
	var pitch: float = current_pitch
	var elapsed: int = now_ms - last_ms
	if elapsed > XP_COMBO_RESET_MS:
		pitch = 1.0
	if elapsed < XP_THROTTLE_MS:
		return {
			"play": false,
			"pitch": pitch,
			"volume_db": 0.0,
			"next_pitch": minf(pitch + XP_THROTTLE_PITCH_STEP, XP_PITCH_MAX),
			"next_last_ms": last_ms,
		}
	return {
		"play": true,
		"pitch": pitch,
		"volume_db": fade_volume_db((pitch - 1.0) / XP_PITCH_SPAN, 0.0, XP_VOLUME_MIN_DB),
		"next_pitch": minf(pitch + XP_PLAY_PITCH_STEP, XP_PITCH_MAX),
		"next_last_ms": now_ms,
	}

# =====================================================================
# SYSTEM AUTOMATYCZNEGO GENEROWANIA MIKSERA NA EKRANIE GRY (Z ZAPISEM)
# =====================================================================
func _build_screen_mixer() -> void:
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 128 
	add_child(_debug_layer)
	
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.position = Vector2(20, 20)
	bg.size = Vector2(400, 550)
	_debug_layer.add_child(bg)
	
	var vbox_main := VBoxContainer.new()
	vbox_main.position = Vector2(30, 30)
	vbox_main.size = Vector2(380, 530)
	_debug_layer.add_child(vbox_main)
	
	var title := Label.new()
	title.text = "--- MIKSER DEWELOPERSKI (F1) ---"
	vbox_main.add_child(title)
	
	# ZIELONY PRZYCISK TRWAŁEGO ZAPISU DO PLIKÓW PROJEKTU
	var save_btn := Button.new()
	save_btn.text = "ZAPISZ ZMIANY NA STAŁE DO PROJEKTU"
	save_btn.modulate = Color(0.2, 1.0, 0.2) 
	save_btn.pressed.connect(func():
		var layout := AudioServer.generate_bus_layout()
		var err := ResourceSaver.save(layout, "res://default_bus_layout.tres")
		if err == OK:
			save_btn.text = "ZAPISANO POMYŚLNIE!"
			await get_tree().create_timer(1.5).timeout
			save_btn.text = "ZAPISZ ZMIANY NA STAŁE DO PROJEKTU"
		else:
			save_btn.text = "BŁĄD ZAPISU! Kod: " + str(err)
	)
	vbox_main.add_child(save_btn)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_main.add_child(scroll)
	
	var vbox_sliders := VBoxContainer.new()
	vbox_sliders.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox_sliders)
	
	for i in AudioServer.get_bus_count():
		var bus_name := AudioServer.get_bus_name(i)
		
		var row := HBoxContainer.new()
		vbox_sliders.add_child(row)
		
		var lbl := Label.new()
		lbl.text = bus_name
		lbl.custom_minimum_size = Vector2(140, 0)
		lbl.clip_text = true
		row.add_child(lbl)
		
		var slider := HSlider.new()
		slider.min_value = -40.0
		slider.max_value = 6.0
		slider.step = 0.5
		slider.value = AudioServer.get_bus_volume_db(i)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		slider.value_changed.connect(func(val: float):
			AudioServer.set_bus_volume_db(i, val)
		)
		row.add_child(slider)
