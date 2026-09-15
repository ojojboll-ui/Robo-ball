extends Node
## Spelar Klättringens farled hopp för hopp och mäter hur stort siktfönster varje
## hopp har: hur många av siktets vinklar som faktiskt landar där de ska.
##
## Körs headless, och en delmängd av hoppen i taget eftersom fysiken går i
## realtid — fyra parallella körningar tar några minuter tillsammans:
##
##     godot --headless --path game res://_route.tscn -- 0 5
##
## Ett tredje argument sätter steghöjden, så att samma farled går att mäta med
## och utan att benen kliver över småhinder:
##
##     godot --headless --path game res://_route.tscn -- 19 20 0
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
	Settings.level_index = 0
	main.call("load_level", 0)
	await get_tree().process_frame
	rb = main.get("_rb")
	level = main.get("_level")
	var floors: Array = level.data["floors"]
	var labels := ["marken", "F", "G", "H", "D", "E", "blocket", "A", "B", "C",
		"C2", "platån", "flaggplatån", "flaggfot"]
	for i in floors.size():
		names[labels[i]] = floors[i]

	var legs: Array[Dictionary] = [
		{"k": "mark", "n": "start → F", "at": Vector2(400, 560), "f": 1, "to": "F", "lo": 10},
		{"k": "mark", "n": "F → G", "at": Vector2(690, 520), "f": 1, "to": "G", "lo": 10},
		{"k": "mark", "n": "G → H", "at": Vector2(1130, 520), "f": 1, "to": "H", "lo": 10},
		{"k": "mark", "n": "H → D", "at": Vector2(1570, 520), "f": 1, "to": "D", "lo": 20},
		{"k": "mark", "n": "D → E", "at": Vector2(1910, 430), "f": 1, "to": "E", "lo": 20},
		{"k": "mark", "n": "E → blocket", "at": Vector2(2250, 360), "f": 1, "to": "blocket", "lo": 20},
		{"k": "grab", "n": "blocket → stång 5", "at": Vector2(2490, 280), "f": -1, "to": 5, "lo": 90, "hi": 170},
		{"k": "hang", "n": "stång 5 → stång 4", "from": 5, "to": 4, "lo": 100, "hi": 170},
		{"k": "hang", "n": "stång 4 → lian 3", "from": 4, "to": 3, "lo": 100, "hi": 170},
		{"k": "hang", "n": "lian 3 → lian 2", "from": 3, "to": 2, "lo": 100, "hi": 170},
		{"k": "hang", "n": "lian 2 → stång 1", "from": 2, "to": 1, "lo": 100, "hi": 170},
		{"k": "hangtop", "n": "stång 1 → balkongen", "from": 1, "to": "balkongen", "lo": 100, "hi": 170},
		{"k": "mark", "n": "balkongen → stång 0", "at": Vector2(600, 30), "f": -1, "to": 0, "lo": 50, "hi": 130, "swing": true},
		{"k": "hangtop", "n": "stång 0 → pelartoppen", "from": 0, "to": "pelartoppen", "lo": 80, "hi": 170},
		{"k": "mark", "n": "pelartoppen → A", "at": Vector2(320, -200), "f": 1, "to": "A", "lo": 20},
		{"k": "mark", "n": "A → B", "at": Vector2(690, -300), "f": 1, "to": "B", "lo": 20},
		{"k": "mark", "n": "B → C", "at": Vector2(1060, -390), "f": 1, "to": "C", "lo": 20},
		{"k": "mark", "n": "C → C2", "at": Vector2(1430, -480), "f": 1, "to": "C2", "lo": 20},
		{"k": "mark", "n": "C2 → platån", "at": Vector2(1800, -570), "f": 1, "to": "platån", "lo": 20},
		# Hela finalen i ett stycke: krönet, backen, skålen och uppstudsen.
		{"k": "final", "n": "platåns krön → flaggan"},
	]
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 0
	var last := int(args[1]) if args.size() > 1 else legs.size()
	if args.size() > 2:
		Settings.step_height = float(args[2])
		print("steghöjd satt till %.0f" % Settings.step_height)
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
##
## Avstampet ligger ungefär två kroppslängder från avsatsens kant. Var han står
## när man trycker spelar roll — vid kanten når hoppet längre — och han går fram
## och tillbaka på avsatsen, så spelaren kan välja. Mätningen tar alltså inte
## bästa läget utan ett normalt.
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
		print("     %3d° -> %s (%.0f, %.0f)" % [deg, at, rb.global_position.x, rb.global_position.y])
		landed[deg] = at
		if at == target:
			hits.append(deg)
	print("%-26s %s" % [label, _window(hits, landed)])

## Hela finalen i ett stycke, precis som en spelare gör den: **ett** tryck på
## platåns krön, och sedan ingenting alls. Han hoppar ner på rampens avsats,
## rullar över krönet, faller genom nedslagsbacken, svänger runt i skålens botten
## och kastas ut ur uppstudsen i en båge till flaggplatån.
##
## Det här är den enda mätningen där ett enda tryck ska bära hela vägen, så den
## räknar inte vinklar som "landar rätt" utan vinklar som **når flaggan**.
func _final() -> void:
	var hits: Array = []
	var landed := {}
	for deg in range(20, 65, 10):
		_reset(Vector2(2800, -650), 1)
		for i in 30:
			await get_tree().physics_frame
		InputSignal.pressed.emit()
		InputSignal.released.emit()
		await get_tree().physics_frame
		rb.aim_deg = float(deg)
		InputSignal.pressed.emit()
		InputSignal.released.emit()
		# Lång svansföring: hela sekvensen tar över tre sekunder, och han nuddar
		# marken flera gånger på vägen — därför får han landa och rulla vidare i
		# stället för att mätningen slutar vid första markkontakten.
		var at := "i luften"
		for i in 420:
			await get_tree().physics_frame
			at = _where()
			if at == "flaggplatån":
				break
		print("     %3d° -> %s" % [deg, at])
		landed[deg] = at
		if at == "flaggplatån":
			hits.append(deg)
	print("%-26s %s" % ["platåns krön → flaggan", _window(hits, landed)])

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
	if absf(feet + 470.0) < 30.0 and x > 2980.0 and x < 3400.0:
		return "rampen"
	if absf(feet + 150.0) < 30.0 and x < 460.0:
		return "pelartoppen"
	if absf(feet - 78.0) < 30.0 and x > 280.0 and x < 1240.0:
		return "balkongen"
	return "annat (%.0f, %.0f)" % [x, feet]
