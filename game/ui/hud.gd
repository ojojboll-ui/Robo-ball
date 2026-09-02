extends CanvasLayer
class_name Hud
## Prototypens överlägg: vilket läge RB är i, och vilka inställningar som gäller.
##
## Det här är inte spelets meny. Den riktiga menyn är ett scanning-UI som går att
## använda med samma enda signal (fas 1, docs/ACCESSIBILITY.md avsnitt 4) —
## utvecklarpanelen här nedan finns bara för att kunna visa skillnaden mellan
## inställningarna under ett speltest.

var _state_label: Label
var _hint_label: Label
var _settings_label: Label
var _dev_label: Label
var _dev_visible := true

func _ready() -> void:
	_state_label = _make_label(Vector2(28, 24), 34)
	_hint_label = _make_label(Vector2(28, 68), 20)
	_settings_label = _make_label(Vector2(28, 104), 16)
	_dev_label = _make_label(Vector2(28, 0), 15)
	_dev_label.anchor_top = 1.0
	_dev_label.anchor_bottom = 1.0
	_dev_label.offset_top = -150.0
	_dev_label.offset_bottom = -12.0

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
			_hint_label.text = "Tryck var som helst för att sikta"
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

func update_settings() -> void:
	var names := ["Klassisk", "Håll och släpp", "Auto-sikte"]
	var variant: String = names[clampi(Settings.control_variant, 0, names.size() - 1)]
	var steps := "mjuk pendel" if Settings.aim_steps < 2 else "%d lägen" % Settings.aim_steps
	_settings_label.text = "\n".join([
		"Styrning: %s" % variant,
		"Pil: %s, hastighet %.1fx" % [steps, Settings.aim_sweep_speed],
		"Slow motion: %d%%" % roundi(Settings.slowmo * 100.0),
		"Spelhastighet: %d%%" % roundi(Settings.game_speed * 100.0),
		"Kantskydd: %s   Förhandsbana: %s" % [
			_yes(Settings.ledge_guard), _yes(Settings.trajectory_preview)],
	])
	_dev_label.visible = _dev_visible
	_dev_label.text = "\n".join([
		"F1 dölj panelen   F2 styrning   F3 slow motion   F4 förhandsbana",
		"F5 kantskydd   F6 vinkelsteg   F7 spelhastighet   F8 börja om",
		"Allt annat — vilken tangent, vilket klick, vilken knapp — är spelets enda signal.",
	])

func toggle_dev() -> void:
	_dev_visible = not _dev_visible
	update_settings()

func _yes(v: bool) -> String:
	return "på" if v else "av"
