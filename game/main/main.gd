extends Node2D
## Fas 0 — lekplatsen.
##
## Syftet är fortfarande ett enda: ta reda på om kärnan är rolig, och kunna
## skruva på den medan någon spelar. Banan är byggd som en verkstad snarare än
## en nivå, och allt som påverkar känslan ligger i inställningspanelen i stället
## för som konstanter i koden.

var _level: Level
var _rb: RoboBall
var _hud: Hud
var _panel: TuningPanel
var _crates: Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BACKDROP)

	_level = Level.new()
	add_child(_level)

	_crates = Node2D.new()
	add_child(_crates)

	_rb = RoboBall.new()
	_rb.global_position = _level.spawn_point()
	_rb.state_changed.connect(_on_state_changed)
	add_child(_rb)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	camera.zoom = Vector2(1.05, 1.05)
	camera.limit_left = -120
	camera.limit_right = int(Level.RIGHT_EDGE + 60.0)
	camera.limit_top = -260
	camera.limit_bottom = 980
	_rb.add_child(camera)

	_hud = Hud.new()
	add_child(_hud)

	_panel = TuningPanel.new()
	_panel.restart_requested.connect(_restart)
	_panel.travel_requested.connect(_travel_to)
	add_child(_panel)

	_build_crates()
	_hud.update_state(_rb.state)

func _build_crates() -> void:
	for child in _crates.get_children():
		child.queue_free()
	for entry in _level.crate_layout():
		var crate := Crate.new()
		crate.box = entry["size"]
		crate.position = entry["pos"]
		_crates.add_child(crate)

func _on_state_changed(state: RoboBall.State) -> void:
	_hud.update_state(state)

func _restart() -> void:
	_build_crates()
	_rb.respawn()

func _travel_to(position: Vector2) -> void:
	_rb.teleport_to(position)

## Funktionstangenter är undantagna från spelets signal (se core/input_signal.gd)
## eftersom inget hjälpmedel skickar dem. De finns för att slippa leta i panelen
## mitt i ett speltest.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			_panel.toggle()
		KEY_F2:
			Settings.control_variant = (Settings.control_variant + 1) % 3
			Settings.notify_changed()
			Settings.save_settings()
			_hud.update_state(_rb.state)
		KEY_F8:
			_restart()
		_:
			return
	get_viewport().set_input_as_handled()
