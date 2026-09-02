extends Node2D
class_name Level
## Lekplatsen — fas 0:s testbana.
##
## Inte en nivå utan en verkstad: ramper av olika lutning, en hoppbacke, en
## kvartspipa, plattformstrappor och sex lådformationer att kasta sig in i.
## Meningen är att kunna känna på varje reglage i inställningspanelen inom
## några sekunder från var man än står.
##
## Marken är sammanhängande hela vägen. Det är ingen slump: RB går av sig själv,
## och en bana där auto-gången kan leda ner i en avgrund straffar spelaren för
## att inte trycka — "aldrig återvändsgränd", docs/DESIGN.md princip 4.

const GROUND_Y := 640.0
const RIGHT_EDGE := 4700.0

var floors: Array[Rect2] = [
	Rect2(-60, GROUND_Y, RIGHT_EDGE + 60.0, 320),  # genomgående mark
	Rect2(1560, 520, 260, 26),                     # plattformstrappa
	Rect2(1900, 420, 240, 26),
	Rect2(2240, 330, 220, 26),
	Rect2(3850, 540, 200, 26),                     # trappan upp mot tornet
	Rect2(4100, 440, 200, 26),
	Rect2(4330, 340, 240, 26),
]

var walls: Array[Rect2] = [
	Rect2(-120, 240, 60, 400),
	Rect2(RIGHT_EDGE, 200, 60, 440),
]

var ramps: Array[PackedVector2Array] = []

func _ready() -> void:
	_build_ramps()
	for r in floors:
		_add_rect(r)
	for r in walls:
		_add_rect(r)
	for poly in ramps:
		_add_polygon(poly)

func _build_ramps() -> void:
	# Svag lutning — RB går uppför utan att tappa fäste.
	ramps.append(PackedVector2Array([
		Vector2(650, GROUND_Y), Vector2(980, GROUND_Y), Vector2(980, GROUND_Y - 110)]))
	# Brantare lutning, men fortfarande gåbar. Var 190 hög på 140 bredd, alltså
	# 54 grader — brantare än RB får fäste i, så den fungerade som en vägg.
	ramps.append(PackedVector2Array([
		Vector2(1060, GROUND_Y), Vector2(1290, GROUND_Y), Vector2(1290, GROUND_Y - 140)]))
	# Hoppbacke: kurvan blir brantare mot slutet, så farten går uppåt.
	ramps.append(_curve(2560.0, 300.0, 150.0, false))
	# Kvartspipa: brant vid foten, flackare på toppen.
	ramps.append(_curve(3700.0, 260.0, 210.0, true))

## Bygger en böjd ramp som ett polygon. `concave` vänder på kurvan: falskt ger
## en hoppbacke som planar ut nedtill, sant ger en kvartspipa.
func _curve(x0: float, width: float, height: float, concave: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var t := float(i) / float(steps)
		var h := (1.0 - sqrt(maxf(0.0, 1.0 - t * t))) if concave else (t * t)
		pts.append(Vector2(x0 + t * width, GROUND_Y - h * height))
	pts.append(Vector2(x0 + width, GROUND_Y))
	pts.append(Vector2(x0, GROUND_Y))
	return pts

func _add_rect(r: Rect2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = r.size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = r.get_center()
	var body := StaticBody2D.new()
	body.add_child(shape)
	add_child(body)

func _add_polygon(points: PackedVector2Array) -> void:
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	var body := StaticBody2D.new()
	body.add_child(shape)
	add_child(body)

func _draw() -> void:
	for r in floors + walls:
		draw_rect(r, Palette.GROUND)
		draw_line(r.position, r.position + Vector2(r.size.x, 0.0), Palette.GROUND_EDGE, 3.0)
	for poly in ramps:
		draw_colored_polygon(poly, Palette.GROUND)
		draw_polyline(poly, Palette.GROUND_EDGE, 3.0, true)

# ------------------------------------------------------------------ innehåll

## Sex formationer med olika karaktär: en pyramid som rasar snyggt, ett torn som
## viker sig, en mur att slå hål i, en bro på pelare, lös småsten, och en stapel
## högst upp i trappan att landa på uppifrån.
func crate_layout() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cube := Vector2(46, 40)
	var small := Vector2(24, 22)
	var plank := Vector2(260, 18)
	var pillar := Vector2(48, 92)

	# Pyramid, bas fem — rasar snyggt om man träffar den snett underifrån
	for row in 5:
		var count := 5 - row
		for i in count:
			out.append({
				"pos": Vector2(3000 + i * (cube.x + 2) + row * (cube.x + 2) * 0.5,
					GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)),
				"size": cube})

	# Enkelbreda torn i tre höjder. Att landa på toppen av en smal stapel är
	# det svåraste fallet för kollisionerna, så de får stå kvar som testfall.
	var towers := {2900: 4, 3320: 6, 3620: 9}
	for x in towers:
		for row in int(towers[x]):
			out.append({
				"pos": Vector2(float(x), GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)),
				"size": cube})

	# Mur, fyra gånger tre
	for col in 4:
		for row in 3:
			out.append({
				"pos": Vector2(3420 + col * (cube.x + 2),
					GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)),
				"size": cube})

	# Bro: två pelare med plankor över. Pelarna är breda nog att stå av sig
	# själva — en bro som redan har rasat när man kommer fram är inte rolig.
	# Plankan är längre än pelaravståndet, så den vilar med överhäng i stället
	# för att balansera på pelarnas innerkanter. Den släpps ett par pixlar över
	# och får landa själv — föremål som startar exakt i kontakt skakar till.
	for side in [0.0, 1.0]:
		out.append({
			"pos": Vector2(4040 + side * 200.0, GROUND_Y - pillar.y * 0.5),
			"size": pillar})
	for layer in 2:
		out.append({
			"pos": Vector2(4140, GROUND_Y - pillar.y - plank.y * 0.5 - 3.0 - layer * (plank.y + 3)),
			"size": plank})

	# Lös småsten direkt vid starten, så att det första RB går in i reagerar.
	for i in 8:
		out.append({
			"pos": Vector2(300 + i * (small.x + 6), GROUND_Y - small.y * 0.5),
			"size": small})

	# Stapel högst upp i trappan, att landa på uppifrån
	for row in 3:
		for i in 2:
			out.append({
				"pos": Vector2(4390 + i * (cube.x + 2), 340 - cube.y * 0.5 - row * (cube.y + 2)),
				"size": cube})
	return out

## Snabbresa i panelen — lekplatsen är för lång för att gå igenom varje gång.
static func spawn_points() -> Array[Dictionary]:
	return [
		{"name": "Start", "pos": Vector2(150, GROUND_Y - 60)},
		{"name": "Ramper", "pos": Vector2(700, GROUND_Y - 60)},
		{"name": "Hoppbacke", "pos": Vector2(2400, GROUND_Y - 60)},
		{"name": "Trappan", "pos": Vector2(1600, 470)},
		{"name": "Lådor", "pos": Vector2(2850, GROUND_Y - 60)},
		{"name": "Bygget", "pos": Vector2(3900, GROUND_Y - 60)},
	]

func spawn_point() -> Vector2:
	var first: Dictionary = Level.spawn_points()[0]
	return first["pos"]
