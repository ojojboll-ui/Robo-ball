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
##
## Innehållet är delat i flikar. Med ett trettiotal reglage blev en enda lista
## längre än vad någon orkar bläddra igenom mitt i ett speltest, och det man
## letar efter hann hinna hamna utanför skärmen.

signal restart_requested
signal travel_requested(position: Vector2)
signal level_requested(index: int)

const PANEL_WIDTH := 540.0
const ROW_HEIGHT := 48.0
const TABS := ["Sikte", "Rörelse", "Rullning", "Föremål", "Hjälp", "Bana"]

var _panel: PanelContainer
var _rows: VBoxContainer
var _scroll: ScrollContainer
var _gear: Button
var _travel: GridContainer
var _tempo_note: Label
## Uppslag från reglagets rubrik till dess delar, så att värden som ändrats
## någon annanstans (tempoknapparna) kan skrivas tillbaka i gränssnittet.
var _rows_by_title: Dictionary = {}
var _open := false

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_gear = Button.new()
	_gear.text = "⚙"
	_gear.add_theme_font_size_override("font_size", 34)
	_gear.custom_minimum_size = Vector2(72, 72)
	_gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gear.position = Vector2(-82, 16)
	_gear.tooltip_text = "Inställningar för speltest"
	_gear.pressed.connect(toggle)
	root.add_child(_gear)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.offset_left = -PANEL_WIDTH
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

	column.add_child(_build_tab_bar())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)

	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	_scroll.add_child(_rows)

	_build_rows()

## Flikarna som en egen rad knappar i stället för Godots TabContainer: dess
## flikhuvuden är för små för ett finger, och sex flikar får inte plats på bredden.
func _build_tab_bar() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var group := ButtonGroup.new()
	for i in TABS.size():
		var button := Button.new()
		button.text = TABS[i]
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == Settings.panel_tab
		button.custom_minimum_size = Vector2(0, 52)
		button.add_theme_font_size_override("font_size", 19)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_tab(button)
		var index := i
		button.pressed.connect(func() -> void:
			Settings.panel_tab = index
			Settings.save_settings()
			_build_rows())
		grid.add_child(button)
	return grid

## Vald flik som svart platta med vit text, övriga som ljusa rutor med svart.
## Standardtemat skiljer bara valt från ovalt med en aning gråton, och vilken
## flik man står i är det första man behöver se när panelen öppnas mitt i ett
## speltest.
func _style_tab(button: Button) -> void:
	var idle := StyleBoxFlat.new()
	idle.bg_color = Palette.SHELL
	idle.border_color = Palette.LINE
	for side in ["left", "right", "top", "bottom"]:
		idle.set("border_width_" + side, 2)
	idle.set_corner_radius_all(6)
	var active := idle.duplicate() as StyleBoxFlat
	active.bg_color = Palette.INK
	active.border_color = Palette.INK
	var hover := idle.duplicate() as StyleBoxFlat
	hover.bg_color = Palette.CRATE
	button.add_theme_stylebox_override("normal", idle)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, active)
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		button.add_theme_color_override(state, Palette.INK)
	for state in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, Palette.SHELL)

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
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_rows_by_title.clear()
	_travel = null
	_tempo_note = null
	if _scroll:
		_scroll.scroll_vertical = 0

	match Settings.panel_tab:
		1: _tab_motion()
		2: _tab_roll()
		3: _tab_objects()
		4: _tab_help()
		5: _tab_level()
		_: _tab_aim()

func _tab_aim() -> void:
	_section("Pilen")
	_slider("Pilens hastighet", 0.1, 2.5, 0.05, Settings.aim_sweep_speed,
		func(v: float) -> void: Settings.aim_sweep_speed = v, "%.2fx")
	_slider("Slow motion vid sikte", 0.05, 1.0, 0.05, Settings.slowmo,
		func(v: float) -> void: Settings.slowmo = v, "%.0f%%", 100.0)
	_slider("Vinkelsteg (0 = mjuk pendel)", 0.0, 9.0, 1.0, float(Settings.aim_steps),
		func(v: float) -> void: Settings.aim_steps = int(v), "%.0f")
	_slider("Bågen börjar vid", -90.0, 270.0, 5.0, Settings.aim_min_deg,
		func(v: float) -> void: Settings.aim_min_deg = v, "%.0f°")
	_slider("Bågen slutar vid", 0.0, 450.0, 5.0, Settings.aim_max_deg,
		func(v: float) -> void: Settings.aim_max_deg = v, "%.0f°")

	_section("Hoppet")
	_slider("Hoppkraft", 300.0, 1800.0, 10.0, Settings.jump_power,
		func(v: float) -> void: Settings.jump_power = v, "%.0f")
	_slider("Gravitation", 600.0, 6000.0, 20.0, Settings.rb_gravity,
		func(v: float) -> void: Settings.rb_gravity = v, "%.0f")
	_tempo_buttons()
	_slider("Extra hopp i luften", 0.0, 2.0, 1.0, float(Settings.air_jumps),
		func(v: float) -> void: Settings.air_jumps = int(v), "%.0f")

func _tab_motion() -> void:
	_section("På marken")
	_slider("Gångfart", 0.3, 2.0, 0.05, Settings.walk_speed,
		func(v: float) -> void: Settings.walk_speed = v, "%.2fx")
	_slider("Gångacceleration", 200.0, 4000.0, 50.0, Settings.walk_accel,
		func(v: float) -> void: Settings.walk_accel = v, "%.0f")
	_slider("Markfäste", 0.0, 600.0, 10.0, Settings.ground_stick,
		func(v: float) -> void: Settings.ground_stick = v, "%.0f")

	_section("Landning och studs")
	_slider("Fart som följer med i landningen", 0.0, 1.5, 0.05, Settings.landing_redirect,
		func(v: float) -> void: Settings.landing_redirect = v, "%.2f")
	_slider("Studs mot väggar", 0.0, 0.9, 0.05, Settings.wall_bounce,
		func(v: float) -> void: Settings.wall_bounce = v, "%.2f")
	_slider("Knuffkraft mot föremål", 0.1, 2.0, 0.05, Settings.push_force,
		func(v: float) -> void: Settings.push_force = v, "%.2f")

	_section("Benen")
	_slider("Benens fjädring", 60.0, 900.0, 10.0, Settings.leg_stiffness,
		func(v: float) -> void: Settings.leg_stiffness = v, "%.0f")
	_slider("Fjädringens dämpning", 4.0, 50.0, 1.0, Settings.leg_damping,
		func(v: float) -> void: Settings.leg_damping = v, "%.0f")

func _tab_roll() -> void:
	_section("När benen åker in")
	_check("Dra in benen i branta backar", Settings.auto_roll,
		func(v: bool) -> void: Settings.auto_roll = v)
	_slider("Brantast benen klarar", 15.0, 60.0, 1.0, Settings.leg_max_slope,
		func(v: float) -> void: Settings.leg_max_slope = v, "%.0f°")
	_slider("Brantast som boll", 30.0, 85.0, 1.0, Settings.roll_max_slope,
		func(v: float) -> void: Settings.roll_max_slope = v, "%.0f°")
	_slider("Blir boll över farten (0 = av)", 0.0, 900.0, 10.0, Settings.roll_speed,
		func(v: float) -> void: Settings.roll_speed = v, "%.0f")

	_section("Hur det går till")
	_slider("Indragningstakt", 1.5, 25.0, 0.5, Settings.tuck_speed,
		func(v: float) -> void: Settings.tuck_speed = v, "%.1f")
	_check("Förbered rullning i luften", Settings.tuck_before_landing,
		func(v: bool) -> void: Settings.tuck_before_landing = v)
	_slider("Hur långt fram han känner av landningen", 0.05, 0.8, 0.05, Settings.tuck_lookahead,
		func(v: float) -> void: Settings.tuck_lookahead = v, "%.2f s")

	_section("Som boll")
	_slider("Rullmotstånd", 0.0, 300.0, 5.0, Settings.roll_friction,
		func(v: float) -> void: Settings.roll_friction = v, "%.0f")

func _tab_objects() -> void:
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
	_check("Effekter (bitar när något går sönder)", Settings.effects,
		func(v: bool) -> void: Settings.effects = v)

func _tab_help() -> void:
	_section("Styrning")
	_choice("Variant", ["Klassisk", "Håll och släpp", "Auto-sikte"],
		Settings.control_variant,
		func(i: int) -> void: Settings.control_variant = i)
	_check("Förhandsbana", Settings.trajectory_preview,
		func(v: bool) -> void: Settings.trajectory_preview = v)
	_check("Kantskydd", Settings.ledge_guard,
		func(v: bool) -> void: Settings.ledge_guard = v)

	_section("Tempo och tålamod")
	_slider("Spelhastighet", 0.25, 1.0, 0.05, Settings.game_speed,
		func(v: float) -> void: Settings.game_speed = v, "%.0f%%", 100.0)
	_slider("Filtrera dubbeltryck", 0.0, 1.0, 0.05, Settings.input_debounce,
		func(v: float) -> void: Settings.input_debounce = v, "%.0f ms", 1000.0)
	_slider("Timeout i siktläget (0 = aldrig)", 0.0, 20.0, 0.5, Settings.aim_timeout,
		func(v: float) -> void: Settings.aim_timeout = v, "%.1f s")

func _tab_level() -> void:
	_section("Bana")
	_choice("Välj bana", Levels.names(), Settings.level_index,
		func(i: int) -> void:
			Settings.level_index = i
			level_requested.emit(i)
			_rebuild_travel())

	var restart := Button.new()
	restart.text = "Börja om — ställ tillbaka alla lådor"
	restart.custom_minimum_size = Vector2(0, 58)
	restart.add_theme_font_size_override("font_size", 20)
	restart.pressed.connect(func() -> void: restart_requested.emit())
	_rows.add_child(restart)

	_section("Snabbresa")
	_travel = GridContainer.new()
	_travel.columns = 3
	_travel.add_theme_constant_override("h_separation", 6)
	_travel.add_theme_constant_override("v_separation", 6)
	_rows.add_child(_travel)
	_rebuild_travel()

	_section("Nollställ")
	# Nollställning hör hemma i ett verktyg för speltest: nästa barn ska kunna
	# börja från samma utgångsläge utan att någon minns vad som skruvats på.
	var reset := Button.new()
	reset.text = "Återställ alla inställningar"
	reset.custom_minimum_size = Vector2(0, 58)
	reset.add_theme_font_size_override("font_size", 20)
	reset.pressed.connect(func() -> void:
		var tab := Settings.panel_tab
		Settings.reset_to_defaults()
		Settings.panel_tab = tab
		Settings.notify_changed()
		_build_rows())
	_rows.add_child(reset)

## Snabbresan hör till banan, så knapparna byggs om när banan byts.
func _rebuild_travel() -> void:
	if _travel == null:
		return
	for child in _travel.get_children():
		_travel.remove_child(child)
		child.queue_free()
	var level: Dictionary = Levels.build(Settings.level_index)
	for point: Dictionary in level.get("spawns", []):
		var pos: Vector2 = point["pos"]
		var button := Button.new()
		button.text = str(point["name"])
		button.custom_minimum_size = Vector2(0, 54)
		button.add_theme_font_size_override("font_size", 19)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: travel_requested.emit(pos))
		_travel.add_child(button)

## Gravitation och hoppkraft hör ihop. Skalas gravitationen med k och kraften med
## roten ur k behåller hoppet exakt samma höjd och längd, men tiden i luften
## ändras med 1/√k. Det är alltså rent tempo — precis den skruv man vill ha när
## fysiken känns flytande, och den som är svårast att hitta för hand.
func _tempo_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for entry in [["Långsammare", 1.0 / 1.4], ["Snabbare fysik", 1.4]]:
		var factor: float = entry[1]
		var button := Button.new()
		button.text = str(entry[0])
		button.custom_minimum_size = Vector2(0, 52)
		button.add_theme_font_size_override("font_size", 19)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: _scale_tempo(factor))
		row.add_child(button)
	_rows.add_child(row)
	_tempo_note = Label.new()
	_tempo_note.add_theme_font_size_override("font_size", 17)
	_tempo_note.add_theme_color_override("font_color", Palette.INK)
	_rows.add_child(_tempo_note)
	_update_tempo_note()

func _scale_tempo(factor: float) -> void:
	Settings.rb_gravity = clampf(Settings.rb_gravity * factor, 600.0, 6000.0)
	Settings.jump_power = clampf(Settings.jump_power * sqrt(factor), 300.0, 1800.0)
	Settings.notify_changed()
	Settings.save_settings()
	_update_tempo_note()
	_sync("Gravitation", Settings.rb_gravity)
	_sync("Hoppkraft", Settings.jump_power)

func _update_tempo_note() -> void:
	if _tempo_note == null:
		return
	var g: float = Settings.rb_gravity
	var v: float = Settings.jump_power
	_tempo_note.text = "Hoppet: %.0f px högt, %.0f px långt, %.2f s i luften" % [
		v * v / (2.0 * g), v * v / g, 2.0 * v / g]

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

## Skriver tillbaka ett värde som ändrats någon annanstans in i sitt reglage.
func _sync(title: String, value: float) -> void:
	if not _rows_by_title.has(title):
		return
	var row: Dictionary = _rows_by_title[title]
	var slider: HSlider = row["slider"]
	var label: Label = row["label"]
	slider.set_value_no_signal(value)
	label.text = (row["fmt"] as String) % (value * (row["scale"] as float))

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

	_rows_by_title[title] = {"slider": slider, "label": value_label, "fmt": fmt, "scale": display_scale}
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = fmt % (v * display_scale)
		setter.call(v)
		Settings.notify_changed()
		_update_tempo_note())
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
