extends CanvasLayer
class_name Hud
## Överlägget: vilket läge RB är i och vad nästa tryck gör.
##
## Medvetet kort. Allt som går att skruva på bor i inställningspanelen, och den
## riktiga spelarmenyn — den som går att använda med en enda signal — kommer i
## fas 1 (docs/ACCESSIBILITY.md avsnitt 4).

var _state_label: Label
var _hint_label: Label
var _foot_label: Label
var _hearts: Control
var _chain_label: Label
var _goal_label: Label
var _hearts_left := 0
var _hearts_max := 0

func _ready() -> void:
	_state_label = _make_label(Vector2(28, 22), 34)
	_hint_label = _make_label(Vector2(28, 66), 22)
	_foot_label = _make_label(Vector2(28, 0), 19)
	_foot_label.anchor_top = 1.0
	_foot_label.anchor_bottom = 1.0
	_foot_label.offset_top = -50.0
	_foot_label.offset_bottom = -14.0
	_foot_label.text = "Tryck var som helst för att spela · kugghjulet ställer in"

	# Hjärtan uppe till höger, och kedjan strax under dem. Båda är tysta när de
	# inte har något att säga: hjärtan syns bara på en bana med fiender, och
	# kedjan bara medan den lever.
	_hearts = Control.new()
	_hearts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hearts.position = Vector2(-320, 22)
	_hearts.custom_minimum_size = Vector2(220, 40)
	_hearts.draw.connect(_draw_hearts)
	_hearts.visible = false
	add_child(_hearts)

	_chain_label = _make_label(Vector2(0, 70), 26)
	_chain_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_chain_label.position = Vector2(-320, 70)
	_chain_label.custom_minimum_size = Vector2(220, 34)
	_chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chain_label.add_theme_color_override("font_color", Palette.PINK)
	_chain_label.text = ""

	_goal_label = _make_label(Vector2.ZERO, 76)
	_goal_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_goal_label.anchor_right = 1.0
	_goal_label.offset_top = 180.0
	_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goal_label.add_theme_color_override("font_color", Palette.PINK)
	_goal_label.add_theme_constant_override("outline_size", 10)
	_goal_label.text = "MÅLET!"
	_goal_label.visible = false

func show_hearts(left: int, most: int) -> void:
	_hearts_left = left
	_hearts_max = most
	_hearts.visible = most > 0
	_hearts.queue_redraw()

## Målet. Stort och mitt i bilden — det är det enda tillfälle spelet har där
## något ska ta över skärmen, och den som inte läser ska ändå se att det small.
func show_goal(on: bool) -> void:
	_goal_label.visible = on

func show_chain(kills: int) -> void:
	_chain_label.text = "KEDJA ×%d" % kills if kills > 1 else ""

func _draw_hearts() -> void:
	for i in _hearts_max:
		var at := Vector2(150.0 + i * 34.0, 16.0)
		var filled := i < _hearts_left
		_draw_heart(at, Palette.PINK if filled else Palette.LINE, filled)

## Ett hjärta av två cirklar och en triangel — nog för gråboxen, och läsbart även
## litet, vilket är hela kravet på en sådan här symbol.
func _draw_heart(at: Vector2, color: Color, filled: bool) -> void:
	var r := 7.0
	var points := PackedVector2Array([
		at + Vector2(-2.0 * r, -1.0), at + Vector2(0.0, 2.0 * r), at + Vector2(2.0 * r, -1.0)])
	if filled:
		_hearts.draw_circle(at + Vector2(-r * 0.9, -r * 0.5), r, color)
		_hearts.draw_circle(at + Vector2(r * 0.9, -r * 0.5), r, color)
		_hearts.draw_colored_polygon(points, color)
	else:
		_hearts.draw_arc(at + Vector2(-r * 0.9, -r * 0.5), r, 0.0, TAU, 12, color, 2.0)
		_hearts.draw_arc(at + Vector2(r * 0.9, -r * 0.5), r, 0.0, TAU, 12, color, 2.0)
		_hearts.draw_polyline(points, color, 2.0)

func _make_label(pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Palette.INK)
	label.add_theme_color_override("font_outline_color", Palette.SHELL)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func update_state(state: RoboBall.State, aim_kind: int = 0) -> void:
	match state:
		RoboBall.State.WALK:
			_state_label.text = "GÅENDE"
			_hint_label.text = "Tryck för att sikta"
		RoboBall.State.ROLL:
			_state_label.text = "RULLAR"
			_hint_label.text = "För brant för benen — tryck för att sikta"
		RoboBall.State.AIM:
			_state_label.text = "SIKTAR"
			if aim_kind == RoboBall.Aim.SHOOT:
				# Skjutsiktet är ett annat verktyg och ska sägas rakt ut: en röd
				# fiende går inte att hoppa på, och då vore "tryck för att hoppa"
				# ett felaktigt råd i just det ögonblick det gäller.
				_state_label.text = "SIKTAR MED LASERN"
				_hint_label.text = "Tryck igen för att skjuta"
				return
			match Settings.control_variant:
				Settings.ControlVariant.CLASSIC:
					_hint_label.text = "Tryck igen för att hoppa"
				Settings.ControlVariant.HOLD_RELEASE:
					_hint_label.text = "Släpp för att hoppa"
				Settings.ControlVariant.AUTO_AIM:
					_hint_label.text = "Spelet siktar åt dig"
		RoboBall.State.AIR:
			_state_label.text = "I LUFTEN"
			_hint_label.text = ""
		RoboBall.State.HANG:
			_state_label.text = "HÄNGER"
			_hint_label.text = "Tryck för att sikta — farten följer med"
