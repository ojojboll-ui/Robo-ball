extends RigidBody2D
class_name Crate
## En låda som går sönder av rörelseenergi.
##
## Angry Birds-modellen: ingen animerar rasandet, det faller ut ur fysiken. RB
## behöver inget "hårt skal" för att krossa saker — skalet höjer bara tröskeln
## (fas 2), det skapar den inte.

const SIZE := Vector2(46.0, 40.0)
const BREAK_SPEED := 380.0   ## under det här studsar lådan bara
const PIECE_LIFETIME := 4.0

var _broken := false

func _ready() -> void:
	mass = 1.2
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)

func take_impact(speed: float) -> void:
	if _broken or speed < BREAK_SPEED:
		return
	_broken = true
	if Settings.effects:
		_spawn_pieces()
	queue_free()

func _spawn_pieces() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for x in 2:
		for y in 2:
			var piece := RigidBody2D.new()
			var rect := RectangleShape2D.new()
			rect.size = SIZE * 0.5
			var shape := CollisionShape2D.new()
			shape.shape = rect
			piece.add_child(shape)
			piece.mass = mass * 0.25
			piece.global_position = global_position + Vector2(
				(x - 0.5) * SIZE.x * 0.5, (y - 0.5) * SIZE.y * 0.5)
			piece.linear_velocity = linear_velocity + Vector2(
				randf_range(-90.0, 90.0), randf_range(-160.0, -40.0))
			piece.angular_velocity = randf_range(-8.0, 8.0)
			var visual := ColorRect.new()
			visual.size = SIZE * 0.5
			visual.position = -SIZE * 0.25
			visual.color = Palette.CRATE
			piece.add_child(visual)
			parent.add_child(piece)
			_expire(piece)

func _expire(piece: Node) -> void:
	var timer := get_tree().create_timer(PIECE_LIFETIME)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(piece):
			piece.queue_free())

func _draw() -> void:
	var r := Rect2(-SIZE * 0.5, SIZE)
	draw_rect(r, Palette.CRATE)
	draw_rect(r, Palette.BLUE, false, 2.5)
	draw_line(r.position, r.position + SIZE, Palette.BLUE, 1.5, true)
