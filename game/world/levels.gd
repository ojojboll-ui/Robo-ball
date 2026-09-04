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
	return ["Lekplatsen", "Rullbanan", "Verkstaden"]

static func build(index: int) -> Dictionary:
	match index:
		1:
			return _roll_test()
		2:
			return _workshop()
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
	var right := 7000.0
	var crates: Array = []
	var cube := Vector2(46, 40)

	# Målet längst bort: allt som är kvar av farten hamnar här.
	for row in 4:
		for i in 2:
			crates.append({"pos": Vector2(4150 + i * (cube.x + 2),
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	var ramps: Array = []
	# Vinkeltrappan: 15, 25, 35, 41, 45 och 55 grader bredvid varandra. De tre
	# sista ligger tätt med flit — de spänner över de två gränserna. Vid 41
	# står han kvar på benen men orkar inte hela vägen upp (klättergränsen går
	# vid 40 med grundvärdena), vid 45 åker benen in. Se docs/METRICS.md.
	var angles := [15.0, 25.0, 35.0, 41.0, 45.0, 55.0]
	for i in angles.size():
		ramps.append(ramp(140.0 + i * 250.0, 190.0, angles[i]))
	# Skålen.
	# Väggarna når 58 grader, alltså långt över vad benen klarar: i skålen
	# rullar han, och rullmotståndet blir synligt som en pendling som dör ut.
	ramps.append(bowl(1620, 840, 340))
	# Puckelbanan — små ojämnheter som bara skakar om farten.
	for i in 4:
		ramps.append(hump(2760.0 + i * 210.0, 190.0, 46.0 + i * 10.0))
	# Kullarna: samma skala som skålen, fast åt andra hållet. Flankerna når 53
	# grader, alltså långt över vad benen klarar — han rullar nedför, tappar fart
	# uppför nästa, och man ser rörelsemängden räcka eller inte räcka.
	for i in 3:
		ramps.append(hump(4500.0 + i * 820.0, 760.0, 320.0))

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
			{"name": "41 grader", "pos": Vector2(900, GROUND_Y - 60)},
			{"name": "45 grader", "pos": Vector2(1150, GROUND_Y - 60)},
			{"name": "55 grader", "pos": Vector2(1400, GROUND_Y - 60)},
			{"name": "Skålen", "pos": Vector2(1700, 320)},
			{"name": "Pucklarna", "pos": Vector2(2700, GROUND_Y - 60)},
			{"name": "Utrullningen", "pos": Vector2(3700, 250)},
			{"name": "Kullarna", "pos": Vector2(4420, GROUND_Y - 60)},
		],
	}

# ---------------------------------------------------------------- verkstaden

## Banan där nya mekaniker provas.
##
## Ingenting här är bestämt som en del av spelet. Verkstaden finns för att kunna
## känna på en mekanik i spelets riktiga fysik innan någon bestämmer sig — det är
## billigare att bygga en station här än att argumentera om den (docs/DECISIONS.md 20).
##
## Två saker styr formen. Studsmattorna ligger *infällda i marken*, för en matta
## som svävar ovanför den blir bara en kant att vända vid. Och stängerna sitter
## fast och sticker ut ur hängande pelare, som i konceptskiss 05 — pelarna hänger
## uppifrån och slutar en bra bit över marken, så att gången under är fri.
static func _workshop() -> Dictionary:
	var right := 5200.0
	var mats := [
		{"pos": Vector2(700, GROUND_Y), "width": 240.0},    ## hoppa ner på den
		{"pos": Vector2(1420, GROUND_Y), "width": 280.0},   ## under avsatsen
		{"pos": Vector2(4300, GROUND_Y), "width": 240.0},   ## kedjans första led
	]

	# Golvet delas upp så att mattornas dukar blir marken där de ligger.
	var floors: Array = []
	var edge := -60.0
	for mat: Dictionary in mats:
		var pos: Vector2 = mat["pos"]
		var half: float = float(mat["width"]) * 0.5
		floors.append(Rect2(edge, GROUND_Y, pos.x - half - edge, 320))
		edge = pos.x + half
	floors.append(Rect2(edge, GROUND_Y, right - edge, 320))

	# Trappan upp till avsatsen, så att man alltid kan ta sig upp igen.
	floors.append(Rect2(900, 520, 130, 22))
	floors.append(Rect2(1080, 430, 130, 22))
	floors.append(Rect2(1300, 350, 240, 24))

	# Avsats att landa på efter stängerna, och målet efter lianerna.
	floors.append(Rect2(2650, 430, 240, 24))
	floors.append(Rect2(4020, 360, 240, 24))

	var walls: Array = [Rect2(-120, 240, 60, 400), Rect2(right, 180, 60, 460)]

	var swings: Array = []
	# Stängerna hänger fritt: bara greppen, inga pelare omkring dem. 185 px över
	# marken, precis inom räckhåll för ett hopp rakt upp.
	for x: float in [1860.0, 2360.0, 4520.0]:
		swings.append({"pos": Vector2(x, 455), "length": 0.0, "kind": "bar"})
	# Lianerna: nästan tre gånger så långa, alltså märkbart långsammare.
	for i in 3:
		swings.append({"pos": Vector2(2950.0 + i * 420.0, 130), "length": 330.0,
			"kind": "vine", "angle": 0.0})

	return {
		"name": "Verkstaden",
		"right_edge": right,
		"floors": floors,
		"walls": walls,
		"ramps": [],
		"crates": [],
		"trampolines": mats,
		"swings": swings,
		"spawns": [
			{"name": "Mattan", "pos": Vector2(360, GROUND_Y - 60)},
			{"name": "Avsatsen", "pos": Vector2(1400, 300)},
			{"name": "Stängerna", "pos": Vector2(1800, GROUND_Y - 60)},
			{"name": "Lianerna", "pos": Vector2(2800, GROUND_Y - 60)},
			{"name": "Kedjan", "pos": Vector2(4150, GROUND_Y - 60)},
		],
	}
