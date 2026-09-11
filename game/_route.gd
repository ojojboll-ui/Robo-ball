extends Node
## Spelar Klättringens farled hopp för hopp och mäter hur stort siktfönster varje
## hopp har: hur många av siktets vinklar som faktiskt landar där de ska.
##
## Körs headless, och en delmängd av hoppen i taget eftersom fysiken går i
## realtid — fyra parallella körningar tar några minuter tillsammans:
##
##     godot --headless --path game res://_route.tscn -- 0 5
##
## Svinghoppen mäts ur ett *dött häng*, alltså utan någon sväng alls. Det är det
## svåraste fallet; med fart i pendeln blir fönstren större. Kravet på banan är
## minst tre vinklar av nio (docs/DECISIONS.md 25).
##
## Två saker verktyget inte klarar: det trycker på klockslag och inte på känsla,
## så ett par körningar per svep missar avstampet och rapporterar fel — de syns
## på att farten står på noll i utskriften. Och det mäter ett hopp i taget, inte
## en hel genomspelning.

var main: Node
var rb: RoboBall
var level: Level
var names := {}

func _ready() -> void:
	main = load("res://main/main.tscn").instantiate()
	add_child(main)
	Settings.level_index = 4
	main.call("load_level", 4)
	await get_tree().process_frame
	rb = main.get("_rb")
	level = main.get("_level")
	var floors: Array = level.data["floors"]
	var labels := ["marken", "F", "G", "H", "D", "E", "blocket", "A", "B", "C",
		"torntopp", "tornfot"]
	for i in floors.size():
		names[labels[i]] = floors[i]

	var legs: Array[Dictionary] = [
		{"k": "mark", "n": "start → F", "at": Vector2(400, 560), "f": 1, "to": "F", "lo": 10},
		{"k": "mark", "n": "F → G", "at": Vector2(600, 520), "f": 1, "to": "G", "lo": 10},
		{"k": "mark", "n": "G → H", "at": Vector2(840, 520), "f": 1, "to": "H", "lo": 10},
		{"k": "mark", "n": "H → D", "at": Vector2(1080, 520), "f": 1, "to": "D", "lo": 20},
		{"k": "mark", "n": "D → E", "at": Vector2(1310, 410), "f": 1, "to": "E", "lo": 20},
		{"k": "mark", "n": "E → blocket", "at": Vector2(1550, 335), "f": 1, "to": "blocket", "lo": 20},
		{"k": "grab", "n": "blocket → stång 4", "at": Vector2(1790, 260), "f": -1, "to": 4, "lo": 90, "hi": 170},
		{"k": "hang", "n": "stång 4 → stång 3", "from": 4, "to": 3, "lo": 100, "hi": 170},
		{"k": "hang", "n": "stång 3 → lian 2", "from": 3, "to": 2, "lo": 100, "hi": 170},
		{"k": "hang", "n": "lian 2 → lian 1", "from": 2, "to": 1, "lo": 100, "hi": 170},
		{"k": "hangtop", "n": "lian 1 → balkongen", "from": 1, "to": "balkongen", "lo": 100, "hi": 170},
		{"k": "mark", "n": "balkongen → stång 0", "at": Vector2(500, 30), "f": -1, "to": 0, "lo": 50, "hi": 130, "swing": true},
		{"k": "hangtop", "n": "stång 0 → pelartoppen", "from": 0, "to": "pelartoppen", "lo": 80, "hi": 170},
		{"k": "mark", "n": "pelartoppen → A", "at": Vector2(250, -200), "f": 1, "to": "A", "lo": 20},
		{"k": "mark", "n": "A → B", "at": Vector2(590, -300), "f": 1, "to": "B", "lo": 20},
		{"k": "mark", "n": "B → C", "at": Vector2(820, -390), "f": 1, "to": "C", "lo": 20},
		{"k": "mark", "n": "C → platån", "at": Vector2(1050, -480), "f": 1, "to": "platån", "lo": 20},
		{"k": "final", "n": "platån → flaggtornet"},
	]
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 0
	var last := int(args[1]) if args.size() > 1 else legs.size()
	for i in range(first, mini(last, legs.size())):
		var leg := legs[i]
		match str(leg["k"]):
			"mark":
				if leg.get("swing", false):
					await _swing_leg(str(leg["n"]), leg["at"], int(leg["f"]),
						int(leg["to"]), int(leg["lo"]), int(leg["hi"]))
				else:
					await _leg(str(leg["n"]), leg["at"], int(leg["f"]), str(leg["to"]),
						int(leg["lo"]), int(leg.get("hi", 90)))
			"grab":
				await _swing_leg(str(leg["n"]), leg["at"], int(leg["f"]), int(leg["to"]),
					int(leg["lo"]), int(leg["hi"]))
			"hang":
				await _hang_leg(str(leg["n"]), int(leg["from"]), int(leg["to"]),
					int(leg["lo"]), int(leg["hi"]))
			"hangtop":
				await _hang_top(str(leg["n"]), int(leg["from"]), str(leg["to"]),
					int(leg["lo"]), int(leg["hi"]))
			"final":
				await _final()

## Ett hopp från mark till mark: ställ honom på avstampet, låt honom gå fram,
## tryck, sikta, tryck — och se var han hamnar.
func _leg(label: String, from: Vector2, face: int, target: String, lo: int, hi: int) -> void:
	var hits: Array = []
	var landed := {}
	for deg in range(lo, hi + 1, 10):
		var at := await _run(from, face, float(deg), 150)
		print("     %3d° -> %s (%d frames, lage %d)" % [deg, at, _used, rb.state])
		landed[deg] = at
		if at == target:
			hits.append(deg)
	print("%-26s %s" % [label, _window(hits, landed)])

func _swing_leg(label: String, from: Vector2, face: int, swing_index: int,
		lo: int, hi: int) -> void:
	var hits: Array = []
	var landed := {}
	for deg in range(lo, hi + 1, 10):
		var at := await _run(from, face, float(deg), 150, swing_index)
		landed[deg] = at
		if at == "sving%d" % swing_index:
			hits.append(deg)
	print("%-26s %s" % [label, _window(hits, landed)])

## Ett hopp från ett grepp till nästa, taget ur ett dött häng — alltså utan någon
## sväng alls. Går det därifrån går det med fart också.
func _hang_leg(label: String, from_index: int, to_index: int, lo: int, hi: int) -> void:
	var hits: Array = []
	var landed := {}
	for deg in range(lo, hi + 1, 10):
		var at := await _run_hang(from_index, float(deg), 180, to_index)
		landed[deg] = at
		if at == "sving%d" % to_index:
			hits.append(deg)
	print("%-26s %s" % [label, _window(hits, landed)])

func _hang_top(label: String, from_index: int, target: String, lo: int, hi: int) -> void:
	var hits: Array = []
	var landed := {}
	for deg in range(lo, hi + 1, 10):
		var at := await _run_hang(from_index, float(deg), 180, -1)
		landed[deg] = at
		if at == target:
			hits.append(deg)
	print("%-26s %s" % [label, _window(hits, landed)])

## Sista hoppet: han rullar ner för platåns backe och skjuter ifrån på avsatsen.
func _final() -> void:
	var hits: Array = []
	var landed := {}
	for deg in range(55, 96, 5):
		_reset(Vector2(1350, -580), 1)
		var speed := 0.0
		var waited := 0
		for i in 400:
			await get_tree().physics_frame
			waited = i
			if rb.global_position.x > 1750.0 and rb.global_position.x < 1960.0 \
					and rb.state != RoboBall.State.AIR and rb.state != RoboBall.State.AIM:
				speed = absf(rb.ground_speed)
				break
		InputSignal.pressed.emit()
		InputSignal.released.emit()
		await get_tree().physics_frame
		rb.aim_deg = float(deg)
		InputSignal.pressed.emit()
		InputSignal.released.emit()
		var at := await _settle(240, -1)
		print("     %3d° -> %s  (x=%.0f, fart %.0f efter %d rutor)" % [
			deg, at, rb.global_position.x, speed, waited])
		landed[deg] = at
		if at == "torntopp":
			hits.append(deg)
	print("%-26s %s" % ["platån → flaggtornet", _window(hits, landed)])

func _window(hits: Array, landed: Dictionary) -> String:
	if hits.is_empty():
		var seen: Array = []
		for k in landed:
			if not landed[k] in seen:
				seen.append(landed[k])
		return "INGEN vinkel träffar — hamnade på %s" % [seen]
	return "%d°–%d° (%d vinklar)" % [hits[0], hits[-1], hits.size()]

func _reset(at: Vector2, face: int) -> void:
	rb.teleport_to(at)
	rb.facing = face
	rb.velocity = Vector2.ZERO
	rb.ground_speed = 0.0
	for swing in get_tree().get_nodes_in_group("swing"):
		(swing as Swing).angle = 0.0
		(swing as Swing).omega = 0.0

func _run(from: Vector2, face: int, deg: float, frames: int, want_swing := -1) -> String:
	_reset(from, face)
	for i in 12:
		await get_tree().physics_frame
	InputSignal.pressed.emit()
	InputSignal.released.emit()
	await get_tree().physics_frame
	rb.aim_deg = deg
	InputSignal.pressed.emit()
	InputSignal.released.emit()
	return await _settle(frames, want_swing)

func _run_hang(index: int, deg: float, frames: int, want_swing: int) -> String:
	var swing := _swing(index)
	_reset(swing.pivot() + Vector2(0.0, 150.0 if swing.kind == Swing.Kind.VINE else 60.0), -1)
	await get_tree().physics_frame
	swing.grab(rb)
	rb.set("_swing", swing)
	rb.set("state", RoboBall.State.HANG)
	await get_tree().physics_frame
	InputSignal.pressed.emit()
	InputSignal.released.emit()
	await get_tree().physics_frame
	rb.aim_deg = deg
	InputSignal.pressed.emit()
	InputSignal.released.emit()
	return await _settle(frames, want_swing)

var _used := 0

func _settle(frames: int, want_swing: int) -> String:
	_used = 0
	for i in frames:
		_used = i
		await get_tree().physics_frame
		if want_swing >= 0 and rb.state == RoboBall.State.HANG:
			return "sving%d" % _index_of(rb.get("_swing"))
		if rb.state == RoboBall.State.WALK or rb.state == RoboBall.State.ROLL:
			if i > 6:
				return _where()
	return "i luften" if rb.state == RoboBall.State.AIR else _where()

func _swing(index: int) -> Swing:
	return get_tree().get_nodes_in_group("swing")[index] as Swing

func _index_of(swing: Object) -> int:
	var all := get_tree().get_nodes_in_group("swing")
	return all.find(swing)

## Var står han? Fötterna avgör, och platån och pelaren räknas för sig eftersom
## de är polygoner och inte rektanglar.
func _where() -> String:
	var feet := rb.global_position.y + 35.0
	var x := rb.global_position.x
	for key in names:
		var r: Rect2 = names[key]
		if absf(feet - r.position.y) < 30.0 and x > r.position.x - 30.0 \
				and x < r.position.x + r.size.x + 30.0:
			return str(key)
	if feet < -490.0 and x > 1220.0 and x < 2020.0:
		return "platån"
	if feet < -110.0 and x < 460.0:
		return "pelartoppen"
	if feet < 130.0 and x > 280.0 and x < 720.0:
		return "balkongen"
	return "annat (%.0f, %.0f)" % [x, feet]
