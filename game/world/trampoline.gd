extends StaticBody2D
class_name Trampoline
## En studsmatta: farten in i duken vänds, farten längs den lämnas i fred.
##
## Studsmattan är den enda mekanik vi hittat hittills som *köper tid utan att
## stanna världen* (docs/DESIGN.md avsnitt 4a). Studsandet sköter sig självt och
## upprepar sig i en takt som väntar in spelaren: missar man ett tryck kommer
## nästa chans av sig själv, i samma rytm, utan att någon räknar ner.
##
## Med studstalet 1.0 studsar han tillbaka lika högt varje gång — ingen energi
## skapas och ingen försvinner. Lägre tal låter rytmen dö ut, vilket är den
## ärliga fysiken för en riktig duk utan någon som pumpar i den.

## Duken ligger i markens nivå och mattan fyller hålet i golvet under den, så
## att man kan gå rakt ut på den. Låg den ovanför marken blev dess kant en vägg
## som RB vände vid — han nådde aldrig fram till att studsa på den.
const DEPTH := 320.0

var width := 220.0
var _flex := 0.0        ## hur djupt duken är nedtryckt just nu, bara för ritning

func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, DEPTH)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0.0, DEPTH * 0.5)
	add_child(shape)

func _process(delta: float) -> void:
	if _flex > 0.0:
		_flex = maxf(0.0, _flex - delta * 700.0)
		queue_redraw()

## Vänder farten in i duken. Returnerar sant om studsen faktiskt blev av — en
## helt lugn RB ska kunna stå på duken i stället för att darra på den.
func bounce(body: Node2D, impact: Vector2, normal: Vector2) -> bool:
	var into := -impact.dot(normal)
	if into < 40.0:
		return false
	# Eftergiften ritas grund och kort. Den var förut både djup och långsam, och
	# eftersom studsen sker på en enda bildruta hann han lämna duken långt innan
	# den kommit tillbaka — då såg det ut som om han landat en bit ovanför den.
	_flex = minf(12.0, into * 0.018)
	queue_redraw()
	# En duk är inte plan utan spänd till en skål, och det är därför man studsar
	# tillbaka mot mitten i stället för att vandra av kanten. Normalen lutar
	# alltså mot mitten i takt med hur långt ut mot kanten han träffar. Utan det
	# drev han av mattan efter tre studsar — mätt: från mitten till 178 px ut.
	var offset := clampf((body.global_position.x - global_position.x) / (width * 0.5), -1.0, 1.0)
	var tilted := normal.rotated(-offset * Settings.trampoline_curve)
	body.velocity = impact - tilted * impact.dot(tilted) * (1.0 + Settings.trampoline_bounce)
	# Ett par pixlar upp, annars träffar han duken igen samma bildruta och
	# studsen räknas två gånger.
	body.global_position += normal * 3.0
	return true

func _draw() -> void:
	var half := width * 0.5
	# Mattan är en del av marken där den ligger, så den fyller golvets hela
	# tjocklek — annars gapar ett hål under duken.
	draw_rect(Rect2(-half, 0.0, width, DEPTH), Palette.GROUND)
	var left := Vector2(-half, 0.0)
	var right := Vector2(half, 0.0)
	# Ramen på var sida, nere i marken.
	draw_line(left, left + Vector2(0.0, 22.0), Palette.GROUND_EDGE, 6.0)
	draw_line(right, right + Vector2(0.0, 22.0), Palette.GROUND_EDGE, 6.0)
	# Duken, nedtryckt så mycket som senaste studsen svarade mot.
	# Duken ritas rakt över den linje han faktiskt landar på. Den ritades förut som
	# en skål med mitten hängande långt under, och då landade han synbart i luften
	# ovanför den — bukten finns i normalen, inte i geometrin, och får inte ritas
	# som om den vore geometri. Djupet nedan är bara det duken ger efter vid en
	# studs, och det försvinner igen.
	var mid := Vector2(0.0, _flex)
	var curve := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		var a := left.lerp(mid, minf(t * 2.0, 1.0))
		var b := mid.lerp(right, maxf(t * 2.0 - 1.0, 0.0))
		curve.append(a if t < 0.5 else b)
	draw_polyline(curve, Palette.PINK, 6.0)
