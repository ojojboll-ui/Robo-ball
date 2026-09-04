extends Node2D
class_name Swing
## Trapets och lian: en pendel man hakar fast i och släpper när man vill.
##
## Pendeln räknas ut, inte animeras: vinkelaccelerationen är −(g/L)·sin θ, samma
## uttryck som en pendel i verkligheten, och gravitationen är spelets egen. Alltså
## svänger en lång lian långsammare än en kort trapets av sig själv, utan att
## någon ställer in det, och tempoknapparna i panelen ändrar svängningstiden lika
## mycket som de ändrar hoppet.
##
## Fastgreppet bevarar rörelsemängd: farten han kommer in med blir vinkelfart
## längs banan, och när han släpper blir vinkelfarten fart igen, i den riktning
## pendeln pekar just då. Det är det som gör trapetsen till spelets tydligaste
## lektion i rörelsemängd — och den enda mekanik hittills där *när* man släpper
## avgör allt, medan *att inte släppa* aldrig är fel: han svänger kvar.

const REGRAB_DELAY := 0.5
## Greppet ritas en bit ovanför den som hänger, så att han hänger *i* det och
## inte sitter mitt i det. Fysiken räknar fortfarande på hela längden.
const HOLD_ABOVE := 20.0

## Avståndet från upphängningen ner till greppet.
var length := 190.0
## Trapets: en styv pinne man hakar benen över. Lian: ett mjukt rep som hänger.
var trapeze := true
var angle := 0.0        ## radianer från rakt ner, positivt åt höger
var omega := 0.0        ## vinkelfart, radianer per sekund
var rider: Node2D = null

var _cooldown := 0.0

func _ready() -> void:
	add_to_group("swing")

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	# Pendelekvationen. Att den gäller lika för tom och lastad pendel är inte
	# en förenkling: en pendels svängningstid beror inte på massan.
	omega += -(Settings.rb_gravity / length) * sin(angle) * delta
	omega -= omega * Settings.swing_damping * delta
	angle += omega * delta
	if rider != null:
		rider.global_position = grip()
		rider.velocity = tangent() * omega * length
	queue_redraw()

func grip() -> Vector2:
	return global_position + Vector2(sin(angle), cos(angle)) * length

## Riktningen han far iväg i om han släpper nu: vinkelrätt mot repet.
func tangent() -> Vector2:
	return Vector2(cos(angle), -sin(angle))

## Hur nära greppet han måste komma. Det är ett tillgänglighetsvärde lika mycket
## som ett fysikvärde: den som inte kan styra i luften ska ändå få tag i trapetsen,
## och en radie i storleksordningen hans egen kropp är skillnaden mellan en mekanik
## som går att använda och en som bara ser bra ut.
static func grab_radius() -> float:
	return Settings.swing_grab_radius

func can_grab() -> bool:
	return rider == null and _cooldown <= 0.0

## Greppet bevarar rörelsemängden: bara farten längs banan får följa med, resten
## tar upphängningen. Det är därför ett grepp i botten av svängen ger mest.
func grab(body: Node2D) -> void:
	rider = body
	omega = body.velocity.dot(tangent()) / length
	body.global_position = grip()

func release() -> Vector2:
	var out := tangent() * omega * length
	rider = null
	_cooldown = REGRAB_DELAY
	return out

func _draw() -> void:
	var g := grip() - global_position
	var hold := g - Vector2(sin(angle), cos(angle)) * HOLD_ABOVE
	if trapeze:
		draw_line(Vector2.ZERO, hold, Palette.GROUND_EDGE, 4.0)
		# Själva pinnen, vinkelrätt mot repet.
		var across := tangent() * 30.0
		draw_line(hold - across, hold + across, Palette.GROUND_EDGE, 7.0)
	else:
		# Lianen ritas som en kedja korta segment som hänger efter i svängen, så
		# att den ser mjuk ut. Den räknas fortfarande som en styv pendel — det
		# syns bara på repet, inte på fysiken.
		var points := PackedVector2Array()
		var reach := length - HOLD_ABOVE
		for i in 9:
			var t := float(i) / 8.0
			var a := angle * (0.35 + 0.65 * t)
			points.append(Vector2(sin(a), cos(a)) * (reach * t))
		draw_polyline(points, Palette.GROUND_EDGE, 5.0)
	draw_circle(Vector2.ZERO, 7.0, Palette.GROUND_EDGE)
