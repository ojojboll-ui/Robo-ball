extends Node2D
class_name Level
## Gråboxbana för fas 0.
##
## Geometrin ligger som data och byggs i kod: plattformar, en ramp och två väggar
## att vända vid. Riktig banredigering med TileMapLayer kommer i fas 1 — poängen
## nu är att kunna känna på hoppet, inte att bygga en värld.

## Marken är sammanhängande. Det är ingen slump: RB går av sig själv, och en
## bana där auto-gången kan leda ner i en avgrund straffar spelaren för att inte
## trycka. Faller han ner från en plattform landar han på marken och kan försöka
## igen — "aldrig återvändsgränd", docs/DESIGN.md princip 4.
var floors: Array[Rect2] = [
	Rect2(-60, 600, 2560, 220),    # genomgående mark
	Rect2(1000, 500, 300, 28),     # svävande plattform, 100 upp
	Rect2(1440, 400, 280, 28),     # 100 till
	Rect2(1880, 310, 260, 28),     # och 90 till
]

## Ramp upp mot höger — RB samlar fart nedför och tappar fart uppför. Toppen är
## också ett bra ställe att känna på kantskyddet: med det på vänder han, med det
## av kliver han ut i luften.
var ramps: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(620, 600), Vector2(880, 600), Vector2(880, 510)]),
]

var walls: Array[Rect2] = [
	Rect2(-120, 200, 60, 400),
	Rect2(2440, 150, 60, 450),
]

func _ready() -> void:
	for r in floors:
		_add_rect(r)
	for r in walls:
		_add_rect(r)
	for poly in ramps:
		_add_polygon(poly)

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

## Var RB börjar, och var lådorna staplas.
func spawn_point() -> Vector2:
	return Vector2(120, 540)

func crate_origin() -> Vector2:
	return Vector2(2160, 600)
