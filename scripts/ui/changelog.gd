extends MenuScreen

# Ekran historii zmian - tekst czytany z ChangelogData (najnowsze na gorze).
# Powrot/ESC: baza MenuScreen. Przewijanie klawiatura: gora/dol przesuwaja liste
# (jedyny focusowalny element to Powrot, wiec strzalki sa wolne dla przewijania).

const SCROLL_STEP_PX := 48

@onready var list_label: Label = get_node_or_null("Panel/Scroll/ChangelogList")
@onready var scroll: ScrollContainer = get_node_or_null("Panel/Scroll")

func _ready() -> void:
	super()
	if list_label:
		list_label.text = ChangelogData.format_all()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_scroll_by(SCROLL_STEP_PX)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		_scroll_by(-SCROLL_STEP_PX)
		get_viewport().set_input_as_handled()
		return
	super(event) # ESC -> powrot (baza)

func _scroll_by(delta_px: int) -> void:
	if scroll:
		scroll.scroll_vertical = maxi(0, scroll.scroll_vertical + delta_px)
