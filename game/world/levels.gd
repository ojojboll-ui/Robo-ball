class_name Levels
extends RefCounted
## Banorna som data.
##
## Varje bana är en ordbok med golv, ramper, väggar, lådor och startpunkter.
## Att hålla dem som data i stället för som scener gör att panelen kan byta bana
## direkt, och att en ny testbana är ett par rader — vilket är hela poängen så
## länge vi bygger i gråbox.

const GROUND_Y := 640.0

static func names() -> Array:
	return ["Lekplatsen", "Rullbanan"]

static func build(index: int) -> Dictionary:
	match index:
		1:
			return _roll_test()
		_:
			return _playground()

# ---------------------------------------------------------------- geometri

## Rak ramp som stiger åt höger, angiven i grader.
static func ramp(x0: float, width: float, degrees: float) -> PackedVector2Array:
	var h := width * tan(deg_to_rad(degrees))
	return PackedVector2Array([
		Vector2(x0, GROUND_Y), Vector2(x0 + width, GROUND_Y), Vector2(x0 + width, GROUND_Y - h)])

## Böjd ramp. `concave` vänder på kurvan: falskt ger en hoppbacke som planar ut
## nedtill, sant ger en kvartspipa som blir brantare mot toppen.
static func curve(x0: float, width: float, height: float, concave: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var t := float(i) / float(steps)
		var h := (1.0 - sqrt(maxf(0.0, 1.0 - t * t))) if concave else (t * t)
		pts.append(Vector2(x0 + t * width, GROUND_Y - h * height))
	pts.append(Vector2(x0 + width, GROUND_Y))
	pts.append(Vector2(x0, GROUND_Y))
	return pts

## Skål: en parabolisk dal med botten i marknivå och väggar som reser sig.
## Här ser man rullmotståndet direkt — han pendlar och tappar höjd för varje
## vända, precis som en kula i en skål ska göra.
static func bowl(x0: float, width: float, depth: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 26
	var half := width * 0.5
	for i in steps + 1:
		var x := x0 + width * float(i) / float(steps)
		var k := (x - (x0 + half)) / half
		pts.append(Vector2(x, GROUND_Y - depth * k * k))
	pts.append(Vector2(x0 + width, GROUND_Y + 260.0))
	pts.append(Vector2(x0, GROUND_Y + 260.0))
	return pts

## Mjuk puckel att rulla över.
static func hump(x0: float, width: float, height: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		var t := float(i) / float(steps)
		pts.append(Vector2(x0 + t * width, GROUND_Y - height * sin(t * PI)))
	pts.append(Vector2(x0 + width, GROUND_Y))
	pts.append(Vector2(x0, GROUND_Y))
	return pts

# ---------------------------------------------------------------- lekplatsen

static func _playground() -> Dictionary:
	var right := 4700.0
	var cube := Vector2(46, 40)
	var small := Vector2(24, 22)
	var plank := Vector2(260, 18)
	var pillar := Vector2(48, 92)
	var crates: Array = []

	# Lös småsten direkt vid starten, så att det första RB går in i reagerar.
	for i in 8:
		crates.append({"pos": Vector2(300 + i * (small.x + 6), GROUND_Y - small.y * 0.5), "size": small})

	# Pyramid, bas fem — rasar snyggt om man träffar den snett underifrån.
	for row in 5:
		for i in 5 - row:
			crates.append({"pos": Vector2(3000 + i * (cube.x + 2) + row * (cube.x + 2) * 0.5,
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	# Enkelbreda torn i tre höjder. Att landa på toppen av en smal stapel är
	# det svåraste fallet för kollisionerna, så de får stå kvar som testfall.
	var towers := {2900: 4, 3320: 6, 3620: 9}
	for x in towers:
		for row in int(towers[x]):
			crates.append({"pos": Vector2(float(x), GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)),
				"size": cube})

	# Mur, fyra gånger tre.
	for col in 4:
		for row in 3:
			crates.append({"pos": Vector2(3420 + col * (cube.x + 2),
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	# Bro: plankor med överhäng på två breda pelare.
	for side in [0.0, 1.0]:
		crates.append({"pos": Vector2(4040 + side * 200.0, GROUND_Y - pillar.y * 0.5), "size": pillar})
	for layer in 2:
		crates.append({"pos": Vector2(4140, GROUND_Y - pillar.y - plank.y * 0.5 - 3.0
			- layer * (plank.y + 3)), "size": plank})

	# Stapel högst upp i trappan, att landa på uppifrån.
	for row in 3:
		for i in 2:
			crates.append({"pos": Vector2(4390 + i * (cube.x + 2),
				340 - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	return {
		"name": "Lekplatsen",
		"right_edge": right,
		"floors": [
			Rect2(-60, GROUND_Y, right + 60.0, 320),
			Rect2(1560, 520, 260, 26),
			Rect2(1900, 420, 240, 26),
			Rect2(2240, 330, 220, 26),
			Rect2(3850, 540, 200, 26),
			Rect2(4100, 440, 200, 26),
			Rect2(4330, 340, 240, 26),
		],
		"walls": [Rect2(-120, 240, 60, 400), Rect2(right, 200, 60, 440)],
		"ramps": [
			ramp(650, 330, 18.4),
			ramp(1060, 230, 31.3),
			curve(2560, 300, 150, false),
			curve(3700, 260, 210, true),
		],
		"crates": crates,
		"spawns": [
			{"name": "Start", "pos": Vector2(150, GROUND_Y - 60)},
			{"name": "Ramper", "pos": Vector2(700, GROUND_Y - 60)},
			{"name": "Hoppbacke", "pos": Vector2(2400, GROUND_Y - 60)},
			{"name": "Trappan", "pos": Vector2(1600, 470)},
			{"name": "Lådor", "pos": Vector2(2850, GROUND_Y - 60)},
			{"name": "Bygget", "pos": Vector2(3900, GROUND_Y - 60)},
		],
	}

# ---------------------------------------------------------------- rullbanan

## En bana som bara handlar om rullfysiken.
##
## Fyra stationer: en trappa av lutningar där man ser exakt var benen åker in
## och var fästet släpper, en skål där rullmotståndet blir synligt som en
## pendling som dör ut, en lång utrullning som visar hur väl rörelsemängden
## bevaras, och puckelbanan som visar vad ojämn mark gör med farten.
static func _roll_test() -> Dictionary:
	var right := 4400.0
	var crates: Array = []
	var cube := Vector2(46, 40)

	# Målet längst bort: allt som är kvar av farten hamnar här.
	for row in 4:
		for i in 2:
			crates.append({"pos": Vector2(4150 + i * (cube.x + 2),
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	var ramps: Array = []
	# Vinkeltrappan: 15, 25, 35, 45 och 55 grader bredvid varandra.
	var angles := [15.0, 25.0, 35.0, 45.0, 55.0]
	for i in angles.size():
		ramps.append(ramp(140.0 + i * 250.0, 190.0, angles[i]))
	# Skålen.
	# Väggarna når 58 grader, alltså långt över vad benen klarar: i skålen
	# rullar han, och rullmotståndet blir synligt som en pendling som dör ut.
	ramps.append(bowl(1620, 840, 340))
	# Puckelbanan.
	for i in 4:
		ramps.append(hump(2760.0 + i * 210.0, 190.0, 46.0 + i * 10.0))

	return {
		"name": "Rullbanan",
		"right_edge": right,
		"floors": [
			Rect2(-60, GROUND_Y, right + 60.0, 320),
			# Avsatsen man släpps från för den långa utrullningen.
			Rect2(3640, 300, 260, 26),
		],
		"walls": [Rect2(-120, 240, 60, 400), Rect2(right, 180, 60, 460)],
		"ramps": ramps,
		"crates": crates,
		"spawns": [
			{"name": "Vinkeltrappan", "pos": Vector2(160, GROUND_Y - 60)},
			{"name": "45 grader", "pos": Vector2(900, GROUND_Y - 60)},
			{"name": "55 grader", "pos": Vector2(1150, GROUND_Y - 60)},
			{"name": "Skålen", "pos": Vector2(1700, 320)},
			{"name": "Pucklarna", "pos": Vector2(2700, GROUND_Y - 60)},
			{"name": "Utrullningen", "pos": Vector2(3700, 250)},
		],
	}
