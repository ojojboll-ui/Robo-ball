class_name Legs
extends RefCounted
## RB:s strutsben — två ben med fotplacering mot marken och en fjädrad kropp.
##
## Gråbox betyder förenklad grafik, inte förenklad mekanik. Benen är fågelben:
## leden mitt på viker sig **bakåt**, inte framåt som ett knä. Det är i själva
## verket fotleden — hos en struts sitter knät högt uppe mot kroppen och det man
## tar för ett bakåtvänt knä är ankeln. Formen är inte dekoration: den avgör hur
## långt han kan kliva, hur högt kroppen bärs och hur mycket ojämn mark som
## fjädras bort innan den når kroppen.
##
## Två saker den här filen löser:
##   1. Fötterna söker upp marken och står stilla medan kroppen rör sig över
##      dem, i stället för att glida med. Ett steg tas först när foten hamnat
##      för långt bak.
##   2. Kroppen hänger i en fjäder ovanför fötterna. Tidigare satt den fast i
##      kollisionskroppen och ärvde varje litet hack i underlaget — därav
##      skakandet uppför ramper.

const THIGH := 17.0        ## höft → ankel, det korta övre benet
const SHIN := 23.0         ## ankel → tå, det långa nedre benet
const TOE := 9.0
const HIP_SPREAD := 7.0    ## halva avståndet mellan höfterna
const BODY_HEIGHT := 46.0  ## kroppens mitt ovanför fotplanet
const LIFT := 13.0         ## hur högt foten lyfts under ett steg
const MAX_SAG := 16.0      ## hur långt kroppen får hamna från kollisionskroppen
const STIFFNESS := 220.0
const DAMPING := 22.0
const MIN_STRIDE := 22.0
const MAX_STRIDE := 46.0

var feet := [Vector2.ZERO, Vector2.ZERO]
var planted := [true, true]
var step_t := [0.0, 0.0]
var step_from := [Vector2.ZERO, Vector2.ZERO]
var step_to := [Vector2.ZERO, Vector2.ZERO]
var step_time := [0.2, 0.2]
var body_point := Vector2.ZERO
var _body_vel := Vector2.ZERO
var _ready := false

func reset(rb: Node2D, normal: Vector2) -> void:
	body_point = rb.global_position + normal * 22.0
	_body_vel = Vector2.ZERO
	var t := Vector2(-normal.y, normal.x)
	for i in 2:
		feet[i] = body_point - normal * BODY_HEIGHT + t * (i * 2.0 - 1.0) * HIP_SPREAD
		planted[i] = true
		step_t[i] = 1.0
	_ready = true

func hips(normal: Vector2) -> Array:
	var t := Vector2(-normal.y, normal.x)
	return [body_point - normal * 10.0 - t * HIP_SPREAD,
		body_point - normal * 10.0 + t * HIP_SPREAD]

func update(rb: Node2D, normal: Vector2, speed: float, grounded: bool, delta: float) -> void:
	if not _ready:
		reset(rb, normal)
	if grounded:
		_step(rb, normal, speed, delta)
	else:
		_dangle(normal, delta)
	_carry_body(rb, normal, delta)

# ---------------------------------------------------------------- stegen

func _step(rb: Node2D, normal: Vector2, speed: float, delta: float) -> void:
	var t := Vector2(-normal.y, normal.x)
	var stride := clampf(MIN_STRIDE + absf(speed) * 0.12, MIN_STRIDE, MAX_STRIDE)
	var hip_list := hips(normal)

	for i in 2:
		if planted[i]:
			continue
		step_t[i] += delta / maxf(step_time[i], 0.02)
		if step_t[i] >= 1.0:
			step_t[i] = 1.0
			planted[i] = true
			feet[i] = step_to[i]
		else:
			var k: float = step_t[i]
			feet[i] = (step_from[i] as Vector2).lerp(step_to[i], k) + normal * sin(k * PI) * LIFT

	# Ett ben i taget. Står båda och ett av dem har hamnat för långt bak tar
	# det steget — det är därför gången blir omväxlande och inte hoppig.
	if planted[0] and planted[1]:
		var worst := -1
		var worst_lag := stride * 0.5
		for i in 2:
			var lag: float = -((feet[i] as Vector2) - (hip_list[i] as Vector2)).dot(t) * signf(speed)
			if speed == 0.0:
				lag = absf(((feet[i] as Vector2) - (hip_list[i] as Vector2)).dot(t)) - stride * 0.4
			if lag > worst_lag:
				worst_lag = lag
				worst = i
		if worst >= 0:
			_begin_step(rb, normal, worst, stride, speed, hip_list[worst])

func _begin_step(rb: Node2D, normal: Vector2, i: int, stride: float, speed: float, hip: Vector2) -> void:
	var t := Vector2(-normal.y, normal.x)
	var forward := signf(speed) if speed != 0.0 else 1.0
	var aim := hip + t * forward * stride * 0.55
	var space := rb.get_world_2d().direct_space_state
	var from := aim + normal * 28.0
	var to := aim - normal * 70.0
	var query := PhysicsRayQueryParameters2D.create(from, to, rb.collision_mask, [rb.get_rid()])
	var hit := space.intersect_ray(query)
	step_from[i] = feet[i]
	step_to[i] = hit["position"] if not hit.is_empty() else aim
	step_t[i] = 0.0
	planted[i] = false
	step_time[i] = clampf(stride / maxf(absf(speed), 40.0) * 0.55, 0.07, 0.32)

## I luften hänger benen ner under kroppen.
func _dangle(normal: Vector2, delta: float) -> void:
	var t := Vector2(-normal.y, normal.x)
	for i in 2:
		var rest := body_point - normal * (BODY_HEIGHT - 6.0) + t * (i * 2.0 - 1.0) * HIP_SPREAD
		feet[i] = (feet[i] as Vector2).lerp(rest, minf(1.0, delta * 9.0))
		planted[i] = false
		step_t[i] = 1.0

# ---------------------------------------------------------------- kroppen

## Fjädringen. Kroppen dras mot en punkt ovanför fötterna i stället för att sitta
## fast i kollisionskroppen, och det är den som gör att småhack i marken inte
## längre skakar hela RB.
func _carry_body(rb: Node2D, normal: Vector2, delta: float) -> void:
	# Kroppen sitter alltid rakt ovanför kollisionskroppen i sidled — en
	# fjädring som också drar i sidled får RB att luta bakåt när han går uppför.
	# Bara höjden fjädrar, och den styrs av var fötterna faktiskt står.
	var anchor := rb.global_position + normal * 22.0
	var support: Vector2 = ((feet[0] as Vector2) + (feet[1] as Vector2)) * 0.5
	var along := (support + normal * BODY_HEIGHT - anchor).dot(normal)
	var target := anchor + normal * clampf(along, -MAX_SAG, MAX_SAG)

	_body_vel += (target - body_point) * STIFFNESS * delta
	_body_vel *= exp(-DAMPING * delta)
	body_point += _body_vel * delta

	# Sista spärren: grafiken får aldrig lämna kollisionskroppen.
	var off := body_point - anchor
	if off.length() > MAX_SAG + 4.0:
		body_point = anchor + off.normalized() * (MAX_SAG + 4.0)
		_body_vel *= 0.5

# ---------------------------------------------------------------- ritning

## Tvåbensled där leden viker sig bakåt — fågelbenets kännetecken.
static func solve(hip: Vector2, foot: Vector2, a: float, b: float, bend: Vector2) -> Vector2:
	var d := foot - hip
	var dist := clampf(d.length(), absf(a - b) + 0.01, a + b - 0.01)
	var dir := d.normalized() if d.length() > 0.001 else Vector2.DOWN
	var x := (dist * dist + a * a - b * b) / (2.0 * dist)
	var y := sqrt(maxf(0.0, a * a - x * x))
	var perp := dir.orthogonal()
	if perp.dot(bend) < 0.0:
		perp = -perp
	return hip + dir * x + perp * y

func draw_into(rb: CanvasItem, normal: Vector2, facing: int, color: Color) -> void:
	var t := Vector2(-normal.y, normal.x)
	var bend := -t * float(facing)
	var hip_list := hips(normal)
	for i in 2:
		var hip: Vector2 = rb.to_local(hip_list[i])
		var foot: Vector2 = rb.to_local(feet[i])
		var ankle := solve(hip, foot, THIGH, SHIN, bend)
		var width := 3.4 if i == 1 else 2.8
		rb.draw_polyline(PackedVector2Array([hip, ankle, foot]), color, width, true)
		rb.draw_circle(ankle, 2.6, color)
		rb.draw_line(foot, foot + t * float(facing) * TOE, color, width, true)
