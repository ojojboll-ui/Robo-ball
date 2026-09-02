extends CanvasLayer
class_name TuningPanel
## Inställningspanel för speltest.
##
## Det här är INTE spelets meny. Den riktiga menyn ska gå att använda med samma
## enda signal som spelet — ett scanning-UI där alternativen markeras i tur och
## ordning (fas 1, docs/ACCESSIBILITY.md avsnitt 4). Panelen här kräver fingrar
## och finns för att den som leder ett speltest ska kunna skruva på tempo, kraft
## och fysik medan barnet spelar, och se skillnaden direkt.
##
## Panelen ligger i ett eget lager och äter sina egna tryck: knappar och reglage
## räknas aldrig som spelets signal, eftersom Godot markerar dem som hanterade
## innan de når InputSignal.

signal restart_requested
signal travel_requested(position: Vector2)

const PANEL_WIDTH := 540.0
const ROW_HEIGHT := 48.0

var _panel: PanelContainer
var _rows: VBoxContainer
var _gear: Button
var _open := false

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var gear := Button.new()
	gear.text = "⚙"
	gear.add_theme_font_size_override("font_size", 34)
	gear.custom_minimum_size = Vector2(72, 72)
	gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear.position = Vector2(-82, 16)
	gear.tooltip_text = "Inställningar för speltest"
	gear.pressed.connect(toggle)
	root.add_child(gear)
	_gear = gear

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_WIDTH
	_panel.offset_top = 0.0
	_panel.offset_bottom = 0.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	# Ljus botten, svart text. Panelen ska se ut som spelet och inte som en
	# systemdialog — och svart text kräver en ljus yta för att gå att läsa.
	var skin := StyleBoxFlat.new()
	skin.bg_color = Palette.PANEL
	skin.border_width_left = 2
	skin.border_color = Palette.LINE
	skin.content_margin_left = 4.0
	_panel.add_theme_stylebox_override("panel", skin)
	root.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var head := HBoxContainer.new()
	var title := Label.new()
	title.text = "Inställningar"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Button.new()
	close.text = "Stäng"
	close.custom_minimum_size = Vector2(110, 52)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(toggle)
	head.add_child(close)
	column.add_child(head)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows)

	_build_rows()

func toggle() -> void:
	_open = not _open
	_panel.visible = _open
	_gear.visible = not _open
	if not _open:
		Settings.save_settings()

func is_open() -> bool:
	return _open

# ---------------------------------------------------------------- innehåll

func _build_rows() -> void:
	_section("Sikte och hopp")
	_slider("Pilens hastighet", 0.1, 2.5, 0.05, Settings.aim_sweep_speed,
		func(v: float) -> void: Settings.aim_sweep_speed = v, "%.2fx")
	_slider("Hoppkraft", 300.0, 1100.0, 10.0, Settings.jump_power,
		func(v: float) -> void: Settings.jump_power = v, "%.0f")
	_slider("Slow motion vid sikte", 0.05, 1.0, 0.05, Settings.slowmo,
		func(v: float) -> void: Settings.slowmo = v, "%.0f%%", 100.0)
	_slider("Vinkelsteg (0 = mjuk pendel)", 0.0, 9.0, 1.0, float(Settings.aim_steps),
		func(v: float) -> void: Settings.aim_steps = int(v), "%.0f")
	_slider("Extra hopp i luften", 0.0, 2.0, 1.0, float(Settings.air_jumps),
		func(v: float) -> void: Settings.air_jumps = int(v), "%.0f")

	_section("RB:s fysik")
	_slider("Gångfart", 0.3, 2.0, 0.05, Settings.walk_speed,
		func(v: float) -> void: Settings.walk_speed = v, "%.2fx")
	_slider("Gravitation", 600.0, 2400.0, 20.0, Settings.rb_gravity,
		func(v: float) -> void: Settings.rb_gravity = v, "%.0f")
	_slider("Studs mot väggar", 0.0, 0.9, 0.05, Settings.wall_bounce,
		func(v: float) -> void: Settings.wall_bounce = v, "%.2f")
	_slider("Knuffkraft mot föremål", 0.1, 2.0, 0.05, Settings.push_force,
		func(v: float) -> void: Settings.push_force = v, "%.2f")

	_section("Lådornas fysik")
	_slider("Tyngd", 0.2, 5.0, 0.1, Settings.crate_mass,
		func(v: float) -> void: Settings.crate_mass = v, "%.1f")
	_slider("Tål innan de krossas", 100.0, 900.0, 10.0, Settings.crate_break_speed,
		func(v: float) -> void: Settings.crate_break_speed = v, "%.0f")
	_slider("Friktion", 0.0, 1.0, 0.05, Settings.crate_friction,
		func(v: float) -> void: Settings.crate_friction = v, "%.2f")
	_slider("Studsighet", 0.0, 0.9, 0.05, Settings.crate_bounce,
		func(v: float) -> void: Settings.crate_bounce = v, "%.2f")
	_slider("Gravitation", 0.2, 3.0, 0.05, Settings.crate_gravity,
		func(v: float) -> void: Settings.crate_gravity = v, "%.2fx")

	_section("Tempo")
	_slider("Spelhastighet", 0.25, 1.0, 0.05, Settings.game_speed,
		func(v: float) -> void: Settings.game_speed = v, "%.0f%%", 100.0)
	_slider("Filtrera dubbeltryck", 0.0, 1.0, 0.05, Settings.input_debounce,
		func(v: float) -> void: Settings.input_debounce = v, "%.0f ms", 1000.0)

	_section("Hjälp")
	_choice("Styrning", ["Klassisk", "Håll och släpp", "Auto-sikte"],
		Settings.control_variant,
		func(i: int) -> void: Settings.control_variant = i)
	_check("Förhandsbana", Settings.trajectory_preview,
		func(v: bool) -> void: Settings.trajectory_preview = v)
	_check("Kantskydd", Settings.ledge_guard,
		func(v: bool) -> void: Settings.ledge_guard = v)
	_check("Effekter", Settings.effects,
		func(v: bool) -> void: Settings.effects = v)

	_section("Lekplatsen")
	var restart := Button.new()
	restart.text = "Börja om — ställ tillbaka alla lådor"
	restart.custom_minimum_size = Vector2(0, 58)
	restart.add_theme_font_size_override("font_size", 20)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	_rows.add_child(restart)
	_travel_buttons()

func _travel_buttons() -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for point in Level.spawn_points():
		var pos: Vector2 = point["pos"]
		var button := Button.new()
		button.text = str(point["name"])
		button.custom_minimum_size = Vector2(0, 54)
		button.add_theme_font_size_override("font_size", 19)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: travel_requested.emit(pos))
		grid.add_child(button)
	_rows.add_child(grid)

# ---------------------------------------------------------------- byggstenar

func _section(title: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_rows.add_child(spacer)
	var label := Label.new()
	label.text = title.to_upper()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Palette.INK)
	_rows.add_child(label)

## En rad: namn och värde överst, sedan minus, reglage och plus. Knapparna finns
## för att ett reglage är svårt att träffa exakt med ett finger på en telefon.
func _slider(title: String, minv: float, maxv: float, step: float, value: float,
		setter: Callable, fmt := "%.2f", display_scale := 1.0) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var head := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Palette.INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	var value_label := Label.new()
	value_label.text = fmt % (value * display_scale)
	value_label.add_theme_font_size_override("font_size", 21)
	value_label.add_theme_color_override("font_color", Palette.INK)
	head.add_child(value_label)
	row.add_child(head)

	var line := HBoxContainer.new()
	var slider := HSlider.new()
	slider.min_value = minv
	slider.max_value = maxv
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var minus := _step_button("−")
	var plus := _step_button("+")
	minus.pressed.connect(func() -> void: slider.value -= step)
	plus.pressed.connect(func() -> void: slider.value += step)

	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = fmt % (v * display_scale)
		setter.call(v)
		Settings.notify_changed())
	# Sparar när fingret släpper, inte för varje pixel under dragningen.
	slider.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			Settings.save_settings())

	line.add_child(minus)
	line.add_child(slider)
	line.add_child(plus)
	row.add_child(line)
	_rows.add_child(row)

func _step_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(54, ROW_HEIGHT)
	button.add_theme_font_size_override("font_size", 26)
	return button

func _check(title: String, value: bool, setter: Callable) -> void:
	var check := CheckButton.new()
	check.text = title
	check.button_pressed = value
	check.custom_minimum_size = Vector2(0, 52)
	check.add_theme_font_size_override("font_size", 21)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		check.add_theme_color_override(state, Palette.INK)
	check.toggled.connect(func(on: bool) -> void:
		setter.call(on)
		Settings.notify_changed()
		Settings.save_settings())
	_rows.add_child(check)

func _choice(title: String, options: Array, current: int, setter: Callable) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Palette.INK)
	_rows.add_child(label)
	var picker := OptionButton.new()
	picker.custom_minimum_size = Vector2(0, 54)
	picker.add_theme_font_size_override("font_size", 21)
	for i in options.size():
		picker.add_item(str(options[i]), i)
	picker.selected = clampi(current, 0, options.size() - 1)
	picker.item_selected.connect(func(index: int) -> void:
		setter.call(index)
		Settings.notify_changed()
		Settings.save_settings())
	_rows.add_child(picker)
