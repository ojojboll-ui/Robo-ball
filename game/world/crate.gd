extends RigidBody2D
class_name Crate
## Ett löst föremål som går sönder av rörelseenergi.
##
## Angry Birds-modellen: ingen animerar rasandet, det faller ut ur fysiken. RB
## behöver inget "hårt skal" för att krossa saker — skalet höjer bara tröskeln
## (fas 2), det skapar den inte.
##
## Storleken sätts utifrån, så att samma klass duger till kuber, plankor och
## pelare i lekplatsens olika formationer.

const DEFAULT_SIZE := Vector2(46.0, 40.0)
const PIECE_LIFETIME := 5.0
const MIN_PIECE := 9.0

var box := DEFAULT_SIZE
var _broken := false
var _shape: CollisionShape2D

func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = box
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	add_child(_shape)
	apply_settings()
	Settings.changed.connect(apply_settings)

## Fysikvärdena är reglage, inte konstanter — de ska gå att skruva på mitt i ett
## speltest och märkas direkt.
func apply_settings() -> void:
	var area := box.x * box.y
	mass = maxf(0.05, Settings.crate_mass * area / (DEFAULT_SIZE.x * DEFAULT_SIZE.y))
	gravity_scale = Settings.crate_gravity
	var mat := physics_material_override
	if mat == null:
		mat = PhysicsMaterial.new()
		physics_material_override = mat
	mat.friction = Settings.crate_friction
	mat.bounce = Settings.crate_bounce

func take_impact(speed: float) -> void:
	if _broken or speed < Settings.crate_break_speed:
		return
	_broken = true
	if Settings.effects and box.x > MIN_PIECE * 2.0 and box.y > MIN_PIECE * 2.0:
		_spawn_pieces()
	queue_free()

func _spawn_pieces() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var half := box * 0.5
	for x in 2:
		for y in 2:
			var piece := Crate.new()
			piece.box = half
			piece.position = position + Vector2(
				(x - 0.5) * half.x, (y - 0.5) * half.y)
			piece.rotation = rotation
			parent.add_child(piece)
			piece.linear_velocity = linear_velocity + Vector2(
				randf_range(-90.0, 90.0), randf_range(-170.0, -50.0))
			piece.angular_velocity = randf_range(-8.0, 8.0)
			piece.expire_after(PIECE_LIFETIME)

## Bitar städas bort, hela lådor blir kvar tills banan startas om.
func expire_after(seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			queue_free())

func _draw() -> void:
	var r := Rect2(-box * 0.5, box)
	draw_rect(r, Palette.CRATE)
	draw_rect(r, Palette.BLUE, false, 2.5)
	draw_line(r.position, r.position + box, Palette.BLUE, 1.5, true)
