extends Node2D
class_name Level
## Bygger en bana ur data från Levels.
##
## Marken är sammanhängande i båda banorna. Det är ingen slump: RB går av sig
## själv, och en bana där auto-gången kan leda ner i en avgrund straffar
## spelaren för att inte trycka — "aldrig återvändsgränd", docs/DESIGN.md
## princip 4.

var data: Dictionary = {}

func load_level(index: int) -> void:
	for child in get_children():
		child.queue_free()
	data = Levels.build(index)
	for r: Rect2 in solids():
		_add_rect(r)
	for poly: PackedVector2Array in ramps():
		_add_polygon(poly)
	for entry: Dictionary in data.get("trampolines", []):
		var pad := Trampoline.new()
		pad.width = float(entry.get("width", 220.0))
		pad.position = entry["pos"]
		add_child(pad)
	for entry: Dictionary in data.get("swings", []):
		var swing := Swing.new()
		swing.length = float(entry.get("length", 190.0))
		swing.kind = Swing.Kind.VINE if entry.get("kind", "bar") == "vine" else Swing.Kind.BAR
		swing.out = float(entry.get("out", -1.0))
		swing.angle = float(entry.get("angle", 0.0))
		swing.position = entry["pos"]
		add_child(swing)
	queue_redraw()

func solids() -> Array:
	var out: Array = []
	out.append_array(data.get("floors", []))
	out.append_array(data.get("walls", []))
	return out

func ramps() -> Array:
	return data.get("ramps", [])

func crate_layout() -> Array:
	return data.get("crates", [])

func spawn_points() -> Array:
	return data.get("spawns", [])

func spawn_point() -> Vector2:
	var points := spawn_points()
	if points.is_empty():
		return Vector2(150, Levels.GROUND_Y - 60)
	var first: Dictionary = points[0]
	return first["pos"]

func right_edge() -> float:
	return float(data.get("right_edge", 4700.0))

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
	for r: Rect2 in solids():
		draw_rect(r, Palette.GROUND)
		draw_line(r.position, r.position + Vector2(r.size.x, 0.0), Palette.GROUND_EDGE, 3.0)
	for poly: PackedVector2Array in ramps():
		draw_colored_polygon(poly, Palette.GROUND)
		draw_polyline(poly, Palette.GROUND_EDGE, 3.0, true)
