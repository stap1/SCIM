class_name UpgradesMenu
extends CanvasLayer

# Popup ULEPSZENIA (sklep meta-progresji, R3c). Wyskakujace okienko z ramka, polprzezroczyste.
# 3 realne ulepszenia: przycisk (kup nastepny poziom) + rzad czarnych kwadratow (pipsy)
# zapalajacych sie na zolto wg poziomu. 12 przyciskow-placeholderow (nieaktywne). Na dole
# RESET (zwrot wszystkich punktow) i WYJSCIE (chowa popup). UI budowane w kodzie.

const PIP_DARK := Color(0.0, 0.0, 0.0, 0.85)
const PIP_LIT := Color(1.0, 0.85, 0.1, 1.0)

var _points_label: Label
var _rows: Dictionary = {}  # id -> {"button":Button, "cost":Label, "pips":Array}

func _ready() -> void:
	layer = 80
	_build()
	visible = false

func open() -> void:
	visible = true
	_refresh()

func _close() -> void:
	visible = false

# Czysta funkcja: czy pip o danym indeksie ma byc zapalony (kupiony poziom).
static func pip_lit(level: int, index: int) -> bool:
	return index < level

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_top = -270.0
	panel.offset_right = 280.0
	panel.offset_bottom = 270.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.16, 0.92)
	sb.border_color = Color(0.85, 0.78, 0.5, 0.9)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(m, 24)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "ULEPSZENIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)

	_points_label = Label.new()
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_points_label)

	# 3 realne ulepszenia (przycisk + pipsy)
	for id in MetaProgress.REAL_IDS:
		var info: Dictionary = MetaProgress.META_UPGRADES[id]
		var row := VBoxContainer.new()
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var btn := Button.new()
		btn.text = str(info["name"])
		btn.tooltip_text = str(info.get("desc", ""))
		btn.custom_minimum_size = Vector2(300, 0)
		btn.pressed.connect(_on_buy.bind(id))
		hb.add_child(btn)
		var cost := Label.new()
		cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(cost)
		row.add_child(hb)
		var pips_hb := HBoxContainer.new()
		pips_hb.add_theme_constant_override("separation", 6)
		var pips: Array = []
		for i in MetaProgress.max_level_of(id):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(20, 20)
			pips_hb.add_child(pip)
			pips.append(pip)
		row.add_child(pips_hb)
		vb.add_child(row)
		_rows[id] = {"button": btn, "cost": cost, "pips": pips}

	# 12 placeholderow (nieaktywne) - przyszle ulepszenia
	var grid := GridContainer.new()
	grid.columns = 6
	for i in 12:
		var pb := Button.new()
		pb.disabled = true
		pb.custom_minimum_size = Vector2(72, 28)
		grid.add_child(pb)
	vb.add_child(grid)

	# RESET + WYJSCIE
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	var reset := Button.new()
	reset.text = "RESET"
	reset.pressed.connect(_on_reset)
	bottom.add_child(reset)
	var exit := Button.new()
	exit.text = "WYJŚCIE"
	exit.pressed.connect(_on_exit)
	bottom.add_child(exit)
	vb.add_child(bottom)

func _on_buy(id: String) -> void:
	if MetaProgress.buy(id):
		AudioManager.play_sfx("ui_click")
	_refresh()

func _on_reset() -> void:
	MetaProgress.reset_upgrades()
	AudioManager.play_sfx("ui_click")
	_refresh()

func _on_exit() -> void:
	AudioManager.play_sfx("ui_click")
	_close()

func _refresh() -> void:
	if _points_label:
		_points_label.text = "Punkty: %d" % MetaProgress.points()
	for id in _rows:
		var lvl: int = MetaProgress.level_of(id)
		var maxl: int = MetaProgress.max_level_of(id)
		var r: Dictionary = _rows[id]
		var pips: Array = r["pips"]
		for i in pips.size():
			pips[i].color = PIP_LIT if pip_lit(lvl, i) else PIP_DARK
		var btn: Button = r["button"]
		var cost: Label = r["cost"]
		if lvl >= maxl:
			btn.disabled = true
			cost.text = "MAX"
		else:
			btn.disabled = not MetaProgress.can_buy(id)
			cost.text = "Koszt: %d" % MetaProgress.cost_of(id, lvl)
