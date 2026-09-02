extends Node
## Spelets enda inmatning.
##
## Hela spelet känner bara till "spelaren gjorde något". Tangentbord, mus,
## pekskärm och handkontroll är adaptrar som mynnar ut här — och eftersom
## praktiskt taget alla hjälpmedel (kontaktmanöverdon, blås/sug, ögonstyrning med
## dwell-klick) emulerar just tangentbord eller musklick, fungerar de utan en enda
## rad extra kod. Villkoret är att vi accepterar *vilken* tangent som helst och
## klick *var som helst*. Bryt aldrig det villkoret.

signal pressed
signal released

## Funktionstangenter och Escape är undantagna och används för utvecklarpanelen.
## Inget hjälpmedel skickar dem, så undantaget kostar ingen tillgänglighet.
const DEV_KEYS := [KEY_ESCAPE, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12]

var _last_press_ms := -100000
var _down := false

func _unhandled_input(event: InputEvent) -> void:
	var down := false
	if event is InputEventKey:
		if event.echo:
			return
		if event.keycode in DEV_KEYS:
			return
		down = event.pressed
	elif event is InputEventMouseButton:
		down = event.pressed
	elif event is InputEventScreenTouch:
		down = event.pressed
	elif event is InputEventJoypadButton:
		down = event.pressed
	else:
		return

	get_viewport().set_input_as_handled()

	if down:
		_press()
	else:
		_release()

func _press() -> void:
	if _down:
		return
	# Debounce: filtrerar skakningar, spasticitet och studsande kontakter.
	var now := Time.get_ticks_msec()
	if now - _last_press_ms < int(Settings.input_debounce * 1000.0):
		return
	_last_press_ms = now
	_down = true
	pressed.emit()

func _release() -> void:
	if not _down:
		return
	_down = false
	released.emit()

func is_down() -> bool:
	return _down
