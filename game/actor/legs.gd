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

const THIGH := 36.0        ## höft → ankel
const SHIN := 37.0         ## ankel → tå. Nästan lika långa, som hos en fågel,
                           ## vilket ger den snäva vinkeln i leden.
const TOE := 9.0
const HIP_SPREAD := 7.0    ## halva avståndet mellan höfterna
## Bollens mitt över fotplanet. Sätts av RoboBall varje bildruta, eftersom den
## krymper när benen dras in — det är den som får benen att vika ihop sig.
var body_height := 48.0
const LIFT := 13.0         ## hur högt foten lyfts under ett steg
const MAX_SAG := 16.0      ## hur långt kroppen får hamna från kollisionskroppen
const MIN_STRIDE := 22.0
const MAX_STRIDE := 52.0
## Så långt benet når. Höften sitter 34 px över marken och ett steg framåt lägger
## till en bit i sidled — med för kort ben blir hypotenusan längre än räckvidden,
## taket nedan drar upp foten, och den nuddar aldrig marken. Benet ska vara långt
## nog att stå böjt, precis som ett fågelben alltid gör.
const REACH := THIGH + SHIN - 3.0
## Hur långt ovanför och nedanför den tänkta fotpunkten vi letar. Kort med flit:
## benet ska söka marken **under sig**, inte närmsta yta i grannskapet.
const PROBE_UP := 12.0
const PROBE_DOWN := 26.0

var feet := [Vector2.ZERO, Vector2.ZERO]
var planted := [true, true]
var step_t := [0.0, 0.0]
var step_from := [Vector2.ZERO, Vector2.ZERO]
var step_to := [Vector2.ZERO, Vector2.ZERO]
var step_time := [0.2, 0.2]
var body_point := Vector2.ZERO
## Hur högt bollens mitt sitter över kollisionskroppens mitt. Sätts av RoboBall
## så att de två aldrig kan glida isär.
var body_lift := 13.0
## Vilken sida leden viker åt, ett värde per ben. Sparas mellan bildrutor med
## hysteres: står foten rakt bakom höften är sidan matematiskt obestämd, och utan
## minne tippar leden fram och tillbaka. Det syntes som att benen böjde sig åt
## fel håll under fall.
var _side := [1.0, 1.0]
var _body_vel := Vector2.ZERO
var _ready := false

func reset(rb: Node2D, normal: Vector2) -> void:
	body_point = rb.global_position + normal * body_lift
	_body_vel = Vector2.ZERO
	var t := Vector2(-normal.y, normal.x)
	for i in 2:
		feet[i] = body_point - normal * body_height + t * (i * 2.0 - 1.0) * HIP_SPREAD
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

	# Skyddsnät: en fot som ändå hamnat orimligt långt bort flyttas hem direkt
	# i stället för att svepa dit över en halv sekund.
	for i in 2:
		if ((feet[i] as Vector2) - (hip_list[i] as Vector2)).length() > REACH * 1.6:
			feet[i] = (hip_list[i] as Vector2) - normal * (body_height - 10.0)
			step_to[i] = feet[i]
			step_t[i] = 1.0
			planted[i] = true

	# En planterad fot får sin höjd från marken, varje bildruta. Stegcykeln
	# bestämmer var foten hamnar i sidled — underlaget bestämmer hur högt.
	# Att räkna ut fothöjden ur kroppens läge i stället var både skört och fel:
	# minsta avvikelse i kroppshöjd lyfte foten från marken.
	var space := rb.get_world_2d().direct_space_state
	for i in 2:
		if not planted[i]:
			continue
		var probe := PhysicsRayQueryParameters2D.create(
			(feet[i] as Vector2) + normal * 12.0, (feet[i] as Vector2) - normal * 30.0,
			rb.collision_mask, [rb.get_rid()])
		var ground := space.intersect_ray(probe)
		if not ground.is_empty() and (ground["normal"] as Vector2).dot(normal) > 0.35:
			feet[i] = ground["position"]
		else:
			# Ingen mark inom räckhåll — foten hänger i luften, troligen kvar
			# från ett fall. Flytta den till det förväntade fotplanet så att
			# strålen hittar marken nästa bildruta.
			feet[i] = (hip_list[i] as Vector2) - normal * (body_height - 10.0)

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

	# Bara **ett** ben får vara i luften åt gången. Utan den regeln utlöste
	# brådskan nedan för båda benen samma bildruta, de steg i takt, och RB
	# hoppade jämfota i stället för att gå. Att växla ben faller ut av sig
	# självt: det ben som stigit landar längst fram, så nästa gång är det det
	# andra som ligger sämst till.
	if planted[0] and planted[1]:
		var choice := -1
		var urgency := 0.0
		for i in 2:
			var d: Vector2 = (feet[i] as Vector2) - (hip_list[i] as Vector2)
			# Hur nära bristningsgränsen benet är, och hur långt bak foten
			# hamnat. Det som är mest akut vinner.
			var stretch := d.length() - REACH * 0.82
			var lag: float = -d.dot(t) * signf(speed) - stride * 0.5
			if speed == 0.0:
				lag = absf(d.dot(t)) - stride * 0.5
			var score := maxf(stretch * 3.0, lag)
			if score > urgency:
				urgency = score
				choice = i
		if choice >= 0:
			_begin_step(rb, normal, choice, stride, speed, hip_list[choice])

	# Hårt tak. Benet är så här långt och inte längre — hellre att foten glider
	# den sista biten än att benet ritas utsträckt.
	for i in 2:
		var d: Vector2 = (feet[i] as Vector2) - (hip_list[i] as Vector2)
		if d.length() > REACH:
			feet[i] = (hip_list[i] as Vector2) + d.normalized() * REACH

func _begin_step(rb: Node2D, normal: Vector2, i: int, stride: float, speed: float, hip: Vector2) -> void:
	var t := Vector2(-normal.y, normal.x)
	var forward := signf(speed) if speed != 0.0 else 1.0
	# Sikta på **fotplanet** framför höften, inte på höftens egen höjd. Utgick
	# strålen från höften nådde den aldrig ner till marken, fallbacken användes
	# varje gång, och foten hamnade en bit över underlaget.
	var aim := hip - normal * (body_height - 10.0) + t * forward * stride * 0.55
	var space := rb.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		aim + normal * PROBE_UP, aim - normal * PROBE_DOWN, rb.collision_mask, [rb.get_rid()])
	var hit := space.intersect_ray(query)

	# Marken under foten, inte närmsta yta åt något håll: träffen måste luta åt
	# samma håll som underlaget han står på, annars är det en vägg eller
	# undersidan av en plattform.
	var target := aim
	if not hit.is_empty() and (hit["normal"] as Vector2).dot(normal) > 0.35:
		target = hit["position"]
	else:
		target = hip - normal * (body_height - 10.0)

	# Och aldrig längre bort än benet räcker.
	var reach_vec := target - hip
	if reach_vec.length() > REACH:
		target = hip + reach_vec.normalized() * REACH

	step_from[i] = feet[i]
	step_to[i] = target
	step_t[i] = 0.0
	planted[i] = false
	step_time[i] = clampf(stride / maxf(absf(speed), 40.0) * 0.55, 0.07, 0.32)

## I luften hänger benen ner under kroppen.
##
## Viktigt: de räknas som planterade där de hänger, inte som mitt i ett steg.
## Markerade vi dem som stegande med stegtiden slut skulle nästa markbildruta
## flytta foten till *förra* stegets slutpunkt — som mycket väl kan ligga tvärs
## över banan. Det var felet som gjorde benen jättelånga vid landning.
func _dangle(normal: Vector2, delta: float) -> void:
	var t := Vector2(-normal.y, normal.x)
	for i in 2:
		var rest := body_point - normal * (body_height - 6.0) + t * (i * 2.0 - 1.0) * HIP_SPREAD
		# Snabbt: släpar fötterna efter kroppen under ett långt hopp hamnar de
		# bakom höften, och då blir ledens sida obestämd.
		feet[i] = (feet[i] as Vector2).lerp(rest, minf(1.0, delta * 16.0))
		planted[i] = true
		step_t[i] = 1.0
		step_to[i] = feet[i]

# ---------------------------------------------------------------- kroppen

## Fjädringen. Kroppen dras mot en punkt ovanför fötterna i stället för att sitta
## fast i kollisionskroppen, och det är den som gör att småhack i marken inte
## längre skakar hela RB.
func _carry_body(rb: Node2D, normal: Vector2, delta: float) -> void:
	# Kroppen sitter alltid rakt ovanför kollisionskroppen i sidled — en
	# fjädring som också drar i sidled får RB att luta bakåt när han går uppför.
	# Bara höjden fjädrar, och den styrs av var fötterna faktiskt står.
	var anchor := rb.global_position + normal * body_lift
	var support: Vector2 = ((feet[0] as Vector2) + (feet[1] as Vector2)) * 0.5
	var along := (support + normal * body_height - anchor).dot(normal)
	var target := anchor + normal * clampf(along, -MAX_SAG, MAX_SAG)

	_body_vel += (target - body_point) * Settings.leg_stiffness * delta
	_body_vel *= exp(-Settings.leg_damping * delta)
	body_point += _body_vel * delta

	# Sista spärren: grafiken får aldrig lämna kollisionskroppen.
	var off := body_point - anchor
	if off.length() > MAX_SAG + 4.0:
		body_point = anchor + off.normalized() * (MAX_SAG + 4.0)
		_body_vel *= 0.5

# ---------------------------------------------------------------- ritning

## Tvåbensled där leden viker sig bakåt — fågelbenets kännetecken. `side` avgör
## vilken sida leden hamnar på; den väljs av draw_into och sparas mellan
## bildrutor, eftersom valet är obestämt när foten står rakt under eller rakt
## bakom höften.
static func solve(hip: Vector2, foot: Vector2, a: float, b: float, side: float) -> Vector2:
	var d := foot - hip
	var dist := clampf(d.length(), absf(a - b) + 0.01, a + b - 0.01)
	var dir := d.normalized() if d.length() > 0.001 else Vector2.DOWN
	var x := (dist * dist + a * a - b * b) / (2.0 * dist)
	var y := sqrt(maxf(0.0, a * a - x * x))
	return hip + dir * x + dir.orthogonal() * y * side

func draw_into(rb: CanvasItem, normal: Vector2, facing: int, color: Color) -> void:
	var t := Vector2(-normal.y, normal.x)
	var bend := -t * float(facing)
	var hip_list := hips(normal)
	for i in 2:
		var hip: Vector2 = rb.to_local(hip_list[i])
		var foot: Vector2 = rb.to_local(feet[i])
		var d := foot - hip
		if d.length() > 0.001:
			var alignment := d.normalized().orthogonal().dot(bend)
			# Byt sida bara när riktningen är entydig. Nära noll behåller vi den
			# gamla, och benet slutar tippa.
			if absf(alignment) > 0.3:
				_side[i] = signf(alignment)
		var ankle := solve(hip, foot, THIGH, SHIN, _side[i])
		var width := 3.4 if i == 1 else 2.8
		rb.draw_polyline(PackedVector2Array([hip, ankle, foot]), color, width, true)
		rb.draw_circle(ankle, 2.6, color)
		rb.draw_line(foot, foot + t * float(facing) * TOE, color, width, true)
