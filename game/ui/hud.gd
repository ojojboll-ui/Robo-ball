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

func _ready() -> void:
	_state_label = _make_label(Vector2(28, 22), 34)
	_hint_label = _make_label(Vector2(28, 66), 22)
	_foot_label = _make_label(Vector2(28, 0), 19)
	_foot_label.anchor_top = 1.0
	_foot_label.anchor_bottom = 1.0
	_foot_label.offset_top = -50.0
	_foot_label.offset_bottom = -14.0
	_foot_label.text = "Tryck var som helst för att spela · kugghjulet ställer in"

func _make_label(pos: Vector2, size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Palette.INK)
	label.add_theme_color_override("font_outline_color", Palette.SHELL)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func update_state(state: RoboBall.State) -> void:
	match state:
		RoboBall.State.WALK:
			_state_label.text = "GÅENDE"
			_hint_label.text = "Tryck för att sikta"
		RoboBall.State.ROLL:
			_state_label.text = "RULLAR"
			_hint_label.text = "För brant för benen — tryck för att sikta"
		RoboBall.State.AIM:
			_state_label.text = "SIKTAR"
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
