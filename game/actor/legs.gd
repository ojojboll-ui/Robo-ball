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
const MIN_STRIDE := 22.0
const MAX_STRIDE := 52.0
## Så långt benet når. Höften sitter 34 px över marken och ett steg framåt lägger
## till en bit i sidled — med för kort ben blir hypotenusan längre än räckvidden,
## taket nedan drar upp foten, och den nuddar aldrig marken. Benet ska vara långt
## nog att stå böjt, precis som ett fågelben alltid gör.
const REACH := THIGH + SHIN - 3.0
## Hur långt ovanför och nedanför den tänkta fotpunkten vi letar. Kort med flit:
## benet ska söka marken **under sig**, inte närmsta yta i grannskapet. Uppåt
## räcker det ändå alltid till steghöjden, annars såg benet inte det RB precis
## klivit upp på och foten sökte sig tillbaka ner till marken han lämnat.
const PROBE_UP := 12.0
const PROBE_DOWN := 26.0

## Hur långt kroppen får hamna från kollisionskroppen — benens spelrum.
static func sag() -> float:
	return Settings.leg_travel

## Hur långt upp benet letar mark. Aldrig kortare än vad han kan kliva upp på.
static func probe_up() -> float:
	return maxf(PROBE_UP, Settings.step_height)

var feet := [Vector2.ZERO, Vector2.ZERO]
var planted := [true, true]
var step_t := [0.0, 0.0]
var step_from := [Vector2.ZERO, Vector2.ZERO]
var step_to := [Vector2.ZERO, Vector2.ZERO]
var step_time := [0.2, 0.2]
## Hur högt foten svingas i just det här steget. Ett steg upp på något måste
## lyfta över det, annars drar foten rakt in i hindrets framkant.
var step_lift := [LIFT, LIFT]
var body_point := Vector2.ZERO
## Hur högt bollens mitt sitter över kollisionskroppens mitt. Sätts av RoboBall
## så att de två aldrig kan glida isär.
var body_lift := 13.0
## Vilken sida leden viker åt, ett värde per ben. Sparas mellan bildrutor med
## hysteres: står foten rakt bakom höften är sidan matematiskt obestämd, och utan
## minne tippar leden fram och tillbaka. Det syntes som att benen böjde sig åt
## fel håll under fall.
var _side := [1.0, 1.0]
var _foot_vel := [Vector2.ZERO, Vector2.ZERO]
var _body_vel := Vector2.ZERO
## Kroppens avstånd till kollisionskroppen när han lämnade marken — det tonar ut
## under flykten och byggs aldrig på av att kastbanan rör sig.
var _drift := Vector2.ZERO
var _was_grounded := true
var _ready := false

func reset(rb: Node2D, normal: Vector2) -> void:
	body_point = rb.global_position + normal * body_lift
	_body_vel = Vector2.ZERO
	# Pendlingens fart räknas i kroppens ram och hör till luften. Den får inte
	# ligga kvar från förra flykten när fötterna sätts ner på nytt.
	_foot_vel = [Vector2.ZERO, Vector2.ZERO]
	_drift = Vector2.ZERO
	_was_grounded = true
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
	# Kroppen placeras först, benen hängs sedan i den. Gjordes det tvärtom
	# flyttades kroppen efter att fötterna satts i förhållande till den, och då
	# ändrades benets längd av kroppens egen rörelse: mätt varierade det 21,7 px
	# under en flykt trots att längden var låst.
	_carry_body(rb, normal, delta, grounded)
	if grounded:
		_step(rb, normal, speed, delta)
	else:
		_dangle(normal, delta, rb.get("velocity") as Vector2)

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
			(feet[i] as Vector2) + normal * probe_up(), (feet[i] as Vector2) - normal * 30.0,
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
			feet[i] = (step_from[i] as Vector2).lerp(step_to[i], k) \
				+ normal * sin(k * PI) * float(step_lift[i])

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
		aim + normal * probe_up(), aim - normal * PROBE_DOWN, rb.collision_mask, [rb.get_rid()])
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
	# Bär steget uppför lyfts foten över kanten, inte bara över marken.
	step_lift[i] = LIFT + maxf(0.0, (target - (feet[i] as Vector2)).dot(normal)) * 0.7
	step_t[i] = 0.0
	planted[i] = false
	step_time[i] = clampf(stride / maxf(absf(speed), 40.0) * 0.55, 0.07, 0.32)

## I luften hänger benen ner under kroppen.
##
## Viktigt: de räknas som planterade där de hänger, inte som mitt i ett steg.
## Markerade vi dem som stegande med stegtiden slut skulle nästa markbildruta
## flytta foten till *förra* stegets slutpunkt — som mycket väl kan ligga tvärs
## över banan. Det var felet som gjorde benen jättelånga vid landning.
## I luften hänger benen i sig själva.
##
## Fötterna dras mot sitt viloläge under höften av en fjäder och bromsas av en
## dämpning — alltså slänger de efter kroppen, svänger förbi och pendlar in, i
## stället för att glida mot en punkt i en fast takt. Att de får släpa är hela
## poängen: det är benen som visar vad kroppen gjort. Fjädern är stark nog att de
## hinner med i ett fall (utan den blev de stående rakt upp som antenner), och
## sträckan är hårt kapad vid vad benet når.
const DANGLE_SPRING := 190.0
const DANGLE_DAMP := 11.0
## Hur fort kroppen sätter sig till rätta på kollisionskroppen när han lämnat
## marken. 14 ger ett par tiondelars sekund, alltså mjukt men utan efterhäng.
const AIR_SETTLE := 14.0
## Hur långt benet hänger från höften i luften. Nästan hela räckvidden: stående
## står fågelbenet böjt för att bära kroppen, hängande bär det ingenting.
const DANGLE_LENGTH := REACH * 0.92
## Den fart luftmotståndet räknas upp till. Snabbare än så ger inget större
## utslag — annars pekar benen rakt upp i ett riktigt långt fall.
const SWAY_TOP := 900.0

## Pendlingen räknas **i kroppens egen ram**, och slängen kommer ur luften.
##
## I ett fall faller kropp och ben lika fort, och den som faller kan inte känna
## att han rör sig — bara att farten ändras. Räknas fjädern mot ett mål som far
## genom världen släpar den efter i stället, med fart/17: benen svängde ut av
## *farten* i stället för av något verkligt, och eftersom en fjäder drar mot en
## punkt blev felet dessutom radiellt — mätt hängde foten 85 px under kroppen på
## väg upp och 3,6 px på väg ner, ett ben som växte och krympte 80 px.
##
## I kroppens ram tar gravitationen ut sig själv, och då återstår det som
## faktiskt får ett hängande ben att släpa: **luften han far genom.** Motståndet
## drar fötterna mot färdriktningen, så slängen följer hur han flyger — bakåt i
## ett språng, uppåt i ett fall, och den vänder mjukt när hoppet vänder. Utan
## den satt benen blickstilla, vilket var lika osant som guppet.
func _dangle(normal: Vector2, delta: float, flight: Vector2) -> void:
	var t := Vector2(-normal.y, normal.x)
	# Motståndet är taget vid en fart, annars pekar benen rakt upp i ett långt
	# fall. Vid taket är utslaget knappt 40 px av benets 64, alltså drygt 35°.
	var drag := -flight.limit_length(SWAY_TOP) * Settings.leg_sway
	for i in 2:
		# Höften och det hängande benets viloläge, båda i kroppens ram. Benet
		# hänger nästan rakt ner: stående står det böjt för att bära kroppen,
		# och i luften bär det ingenting.
		var hip := -normal * 10.0 + t * (i * 2.0 - 1.0) * HIP_SPREAD
		var rest := hip - normal * DANGLE_LENGTH
		var off: Vector2 = (feet[i] as Vector2) - body_point
		var vel: Vector2 = _foot_vel[i]
		vel += ((rest - off) * DANGLE_SPRING + drag) * delta
		vel *= exp(-DANGLE_DAMP * delta)
		off += vel * delta
		# **Ett ben svänger i vinkel, det teleskoperar inte.** Fjädern och luften
		# får peka ut riktningen, men längden är benets egen.
		var hang := off - hip
		if hang.length() > 0.001:
			off = hip + hang.normalized() * DANGLE_LENGTH
			vel = vel.slide(hang.normalized())
		_foot_vel[i] = vel
		feet[i] = body_point + off
		planted[i] = true
		step_t[i] = 1.0
		step_to[i] = feet[i]

## Hängande: benen hakas över stången eller lianen och kroppen hänger under.
##
## Det är samma ben, samma IK och samma ritning som när han går — bara med
## fötterna satta i greppet i stället för på marken, och med kroppens "upp"
## vänd åt andra hållet. Att han hänger upp och ner faller alltså ut av
## geometrin, ingenting animeras.
func hang(rb: Node2D, grip: Vector2, delta: float) -> void:
	body_point = rb.global_position
	var up := (rb.global_position - grip)
	if up.length() < 0.001:
		up = Vector2.DOWN
	up = up.normalized()
	var across := Vector2(-up.y, up.x)
	for i in 2:
		# Fötterna sitter på var sin sida om stången, som när man hakar knäna
		# över en gren.
		var target := grip + across * (i * 2.0 - 1.0) * (HIP_SPREAD + 3.0)
		feet[i] = (feet[i] as Vector2).lerp(target, minf(1.0, delta * 22.0))
		planted[i] = true
		step_t[i] = 1.0
		step_to[i] = feet[i]
		step_from[i] = feet[i]

# ---------------------------------------------------------------- kroppen

## Fjädringen. Kroppen dras mot en punkt ovanför fötterna i stället för att sitta
## fast i kollisionskroppen, och det är den som gör att småhack i marken inte
## längre skakar hela RB.
func _carry_body(rb: Node2D, normal: Vector2, delta: float, grounded: bool) -> void:
	# Kroppen sitter alltid rakt ovanför kollisionskroppen i sidled — en
	# fjädring som också drar i sidled får RB att luta bakåt när han går uppför.
	# Bara höjden fjädrar, och den styrs av var fötterna faktiskt står.
	var anchor := rb.global_position + normal * body_lift
	var travel := sag()
	var target := anchor

	# **I luften fjädrar ingenting.** Fjädringen finns för att marken är ojämn:
	# fötterna står på den, och kroppen får hänga mjukt ovanför dem i stället
	# för att ärva varje hack. I ett fall finns ingen mark att fjädra mot — då
	# är kroppen tyngden, och den följer kastbanan rakt av.
	#
	# Och en fjäder *måste* släpa efter ett mål som rör sig: med styvheten 220
	# och dämpningen 22 blir släpet fart/10, alltså 60 px i 600 px/s, kapat vid
	# spärren. Mätt hängde kroppen därför 28,6 px under kollisionskroppen på väg
	# upp och 29,4 px ovanför den på väg ner — **58 px vandring genom
	# vändpunkten**, och den vandringen *är* guppet. Det såg ut som att vikten
	# satt i benen, och i räkningen gjorde den faktiskt det.
	#
	# I luften får avståndet i stället rinna av mot noll och sedan ligga där, så
	# att kroppen sitter exakt på kollisionskroppen hela flykten. Det som är kvar
	# från marken tonar ut på ett par tiondelar i stället för att slå om.
	if not grounded:
		# Avståndet är ett eget tillstånd som bara tonar ut. Räknas det i stället
		# om mot kollisionskroppen varje bildruta matas rörelsen in på nytt varje
		# gång, och kvar blir ett stadigt släp på nästan fyra bildrutor — mätt
		# 41 px i 660 px/s, alltså precis det gupp som skulle bort.
		if _was_grounded:
			_drift = body_point - anchor
			_was_grounded = false
		_drift *= exp(-AIR_SETTLE * delta)
		body_point = anchor + _drift
		_body_vel = Vector2.ZERO
		return

	_was_grounded = true
	var support: Vector2 = ((feet[0] as Vector2) + (feet[1] as Vector2)) * 0.5
	var along := (support + normal * body_height - anchor).dot(normal)
	target = anchor + normal * clampf(along, -travel, travel)

	_body_vel += (target - body_point) * Settings.leg_stiffness * delta
	_body_vel *= exp(-Settings.leg_damping * delta)
	body_point += _body_vel * delta

	# Sista spärren: grafiken får aldrig lämna kollisionskroppen.
	var off := body_point - anchor
	if off.length() > travel + 4.0:
		body_point = anchor + off.normalized() * (travel + 4.0)
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
