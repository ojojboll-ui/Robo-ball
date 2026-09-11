extends Node2D
class_name Flag
## Målet: en flagga på en stång.
##
## Det första spelet har som är ett *mål* och inte en mekanik. Den behöver därför
## inget annat än att synas på håll och att märka när RB når fram — ingen text,
## ingen knapp, ingen meny. Att gå in i den räcker, och eftersom RB går av sig
## själv når han den utan att spelaren behöver göra något sista precist.

signal reached

const POLE := 110.0            ## stångens höjd över marken
const CLOTH := Vector2(64.0, 40.0)

var taken := false
var _wave := 0.0

func _ready() -> void:
	add_to_group("flag")

func _process(delta: float) -> void:
	if not taken:
		return
	# Duken viftar en stund efter att han nått fram. Den enda "animationen" i
	# spelet, och den räknas ut som allt annat.
	_wave += delta
	queue_redraw()

## Träffytan är hela stången, inte bara duken: den som kommer rullande längs
## marken ska nå målet lika säkert som den som landar ovanpå det.
func rect() -> Rect2:
	return Rect2(global_position - Vector2(30.0, POLE), Vector2(60.0, POLE + 10.0))

func touch(body: Rect2) -> bool:
	if taken or not rect().intersects(body):
		return false
	taken = true
	reached.emit()
	queue_redraw()
	return true

func _draw() -> void:
	draw_line(Vector2(0.0, 8.0), Vector2(0.0, -POLE), Palette.INK, 6.0)
	draw_circle(Vector2(0.0, -POLE), 7.0, Palette.INK)
	# Duken hänger på stångens högra sida och sträcks ut när den är tagen.
	var pull := 1.0 if taken else 0.72
	var flap := sin(_wave * 7.0) * 6.0 if taken else 0.0
	var cloth := PackedVector2Array([
		Vector2(3.0, -POLE + 4.0),
		Vector2(3.0 + CLOTH.x * pull, -POLE + CLOTH.y * 0.5 + flap),
		Vector2(3.0, -POLE + CLOTH.y),
	])
	draw_colored_polygon(cloth, Palette.PINK)
	draw_polyline(cloth, Palette.INK, 3.0, true)
