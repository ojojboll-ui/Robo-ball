extends Node2D
## Fas 0-prototypen.
##
## Syftet är ett enda: ta reda på om kärnan är rolig innan vi bygger något runt
## den. Auto-gång, siktläge med pendelpil och förhandsbana, ballistiskt hopp, och
## en hög lådor att krossa. Ingen grafik, en bana, allt i gråbox.
##
## Milstolpe för fasen: någon som aldrig sett spelet tar sig genom banan med
## mellanslag som enda knapp — i en webbläsare, via en länk — och tycker det är kul.

const CRATE_COLUMNS := 3
const CRATE_ROWS := 3

var _level: Level
var _rb: RoboBall
var _hud: Hud

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BACKDROP)

	_level = Level.new()
	add_child(_level)

	_rb = RoboBall.new()
	_rb.global_position = _level.spawn_point()
	_rb.state_changed.connect(_on_state_changed)
	add_child(_rb)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	camera.zoom = Vector2(1.15, 1.15)
	_rb.add_child(camera)

	_hud = Hud.new()
	add_child(_hud)

	_build_crates()
	_hud.update_state(_rb.state)
	_hud.update_settings()

func _build_crates() -> void:
	var origin := _level.crate_origin()
	for col in CRATE_COLUMNS:
		for row in CRATE_ROWS:
			var crate := Crate.new()
			crate.position = origin + Vector2(
				col * (Crate.SIZE.x + 2.0),
				-Crate.SIZE.y * 0.5 - row * (Crate.SIZE.y + 2.0))
			add_child(crate)

func _on_state_changed(state: RoboBall.State) -> void:
	_hud.update_state(state)

## Utvecklarpanelen. Funktionstangenter är undantagna från spelets signal
## (se core/input_signal.gd) eftersom inget hjälpmedel skickar dem — de finns
## bara för att kunna växla mellan inställningar mitt i ett speltest.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			_hud.toggle_dev()
		KEY_F2:
			Settings.control_variant = (Settings.control_variant + 1) % 3
		KEY_F3:
			Settings.slowmo = _cycle(Settings.slowmo, [0.05, 0.1, 0.2, 0.4, 1.0])
		KEY_F4:
			Settings.trajectory_preview = not Settings.trajectory_preview
		KEY_F5:
			Settings.ledge_guard = not Settings.ledge_guard
		KEY_F6:
			Settings.aim_steps = int(_cycle(float(Settings.aim_steps), [0.0, 3.0, 5.0, 7.0, 9.0]))
		KEY_F7:
			Settings.game_speed = _cycle(Settings.game_speed, [0.25, 0.5, 0.75, 1.0])
		KEY_F8:
			_restart()
		_:
			return
	get_viewport().set_input_as_handled()
	Settings.notify_changed()
	Settings.save_settings()
	_hud.update_settings()
	_hud.update_state(_rb.state)

func _cycle(current: float, values: Array) -> float:
	for i in values.size():
		if is_equal_approx(current, float(values[i])):
			return float(values[(i + 1) % values.size()])
	return float(values[0])

func _restart() -> void:
	for child in get_children():
		if child is Crate or (child is RigidBody2D and not child is Crate):
			child.queue_free()
	_build_crates()
	_rb.respawn()
