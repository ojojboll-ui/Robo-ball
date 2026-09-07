extends CharacterBody2D
class_name Enemy
## En fiende: en fyrkant med elaka ögon, som går fram och tillbaka på marken.
##
## Två sorter, och skillnaden är hela poängen med dem:
##
## * **Blå** går att hoppa på. Träffar RB den ovanifrån dör den. Men går eller
##   rullar han in i den på marken är det han som tar skada — samma fiende är
##   alltså farlig eller ofarlig beroende på vad han själv gör, vilket är den
##   enklaste sortens regel ett barn kan läsa av på egen hand.
## * **Röd** bryr sig inte om att bli hoppad på och skadar RB så fort den nuddar
##   honom. Den går bara att skjuta.
##
## Fienderna ligger i ett eget kollisionslager: de går på världens golv och
## väggar, men RB åker aldrig in i dem som i en låda. Vad en beröring betyder
## avgörs av spelets regler och inte av motorns knuffar.

enum Kind { BLUE, RED }

const SIZE := Vector2(42.0, 42.0)
const GRAVITY := 1400.0
## Hur långt fram den känner efter mark innan den vänder vid en kant.
const LEDGE_PROBE := 30.0

signal killed(enemy: Enemy, by_laser: bool)

var kind := Kind.BLUE
var facing := -1
var _dead := false
var _blink := 0.0

func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = SIZE
	shape.shape = box
	add_child(shape)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _blink > 0.0:
		_blink = maxf(0.0, _blink - delta)
	var speed: float = Settings.enemy_speed * (1.0 if kind == Kind.BLUE else 0.6)
	velocity.x = facing * speed
	velocity.y += GRAVITY * delta
	move_and_slide()
	if is_on_wall() or (is_on_floor() and not _ground_ahead()):
		facing = -facing
	queue_redraw()

## Finns det mark framför fötterna? Annars vänder den, av samma skäl som RB gör
## det: en fiende som går ner i en avgrund är en fiende spelaren aldrig möter.
func _ground_ahead() -> bool:
	var from := global_position + Vector2(facing * (SIZE.x * 0.5 + 4.0), SIZE.y * 0.4)
	var query := PhysicsRayQueryParameters2D.create(
		from, from + Vector2(0.0, LEDGE_PROBE), collision_mask, [get_rid()])
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func rect() -> Rect2:
	return Rect2(global_position - SIZE * 0.5, SIZE)

## Ovansidan, den enda yta en blå fiende är sårbar på.
func top() -> float:
	return global_position.y - SIZE.y * 0.5

func die(by_laser: bool) -> void:
	if _dead:
		return
	_dead = true
	killed.emit(self, by_laser)
	if Settings.effects:
		_scatter()
	queue_free()

## Fyra bitar som far isär, härledda ur var den stod — ingen slump, av samma skäl
## som lådorna: samma smäll ska ge samma resultat (docs/DESIGN.md 4a).
func _scatter() -> void:
	var parent := get_parent()
	if parent == null:
		return
	for i in 4:
		var piece := Crate.new()
		piece.box = SIZE * 0.4
		piece.position = position + Vector2((i % 2) * 2.0 - 1.0, (i / 2) * 2.0 - 1.0) * SIZE * 0.25
		parent.add_child(piece)
		piece.apply_impulse(Vector2((i % 2) * 2.0 - 1.0, -1.0) * 90.0)

func _draw() -> void:
	var half := SIZE * 0.5
	var body := Palette.BLUE if kind == Kind.BLUE else Palette.PINK
	draw_rect(Rect2(-half, SIZE), body)
	draw_rect(Rect2(-half, SIZE), Palette.INK, false, 3.0)
	# Elaka ögon: två vita fält med sneda lock över.
	for s in [-1.0, 1.0]:
		var eye := Vector2(s * 9.0, -3.0)
		draw_circle(eye, 7.0, Palette.SHELL)
		draw_circle(eye + Vector2(facing * 2.0, 1.0), 3.4, Palette.INK)
		# Locket lutar in mot mitten, vilket är hela knepet med en elak blick.
		draw_line(eye + Vector2(-7.0, -6.0 + s * 2.0), eye + Vector2(7.0, -6.0 - s * 2.0),
			Palette.INK, 3.5)
