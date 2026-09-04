extends Node2D
class_name Swing
## Två saker att hänga i: stången och lianen.
##
## **Stången** sitter fast och sticker ut vågrätt ur en vägg, som en flaggstång
## (konceptskiss 05). RB hakar benen över den och snurrar runt den. Eftersom han
## hänger tätt intill blir radien liten och varvet snabbt: farten han kommer in
## med är farten han far ut med, men riktningen är hans att välja. Stången är
## alltså ingen fartkälla utan en *riktningsväxel* — den enda mekanik vi har där
## ett tryck kan peka farten vart som helst utan att någon fart går förlorad.
##
## **Lianen** hänger i en punkt och svänger själv. Där är repet långt, varvet
## långsamt, och pendeln byter höjd mot fart som en pendel ska.
##
## Båda räknas ut, inte animeras: vinkelaccelerationen är −(g/r)·sin θ, samma
## uttryck som en pendel i verkligheten, och gravitationen är spelets egen. En
## lång lian svänger därför långsammare än en kort stång utan att någon ställer
## in det, och tempoknapparna i panelen ändrar svängningstiden lika mycket som
## de ändrar hoppet.
##
## Greppet bevarar rörelsemängd: farten längs banan följer med, resten tar
## upphängningen. Ett tryck släpper, och farten följer med ut i luften. Att inte
## släppa är alltid tillåtet — han hänger kvar.

enum Kind { BAR, VINE }

const REGRAB_DELAY := 0.5
## Hur långt under stången han hänger när benen är hakade över den. Kroppen är
## 70 px hög, så ungefär en kroppslängd — och radien avgör varvtiden: med 34 px
## snurrade han 2,3 varv i sekunden vid ett snabbt grepp, vilket varken går att
## läsa eller att träffa rätt i.
const BAR_HOLD := 60.0
## Greppet ritas en bit ovanför den som hänger, så att han hänger *i* det.
const HOLD_ABOVE := 20.0

var kind := Kind.BAR
## Stången: hur långt ut ur väggen den sticker. Lianen: repets längd.
var length := 120.0
## Åt vilket håll stången sticker ut från sitt fäste. −1 = åt vänster.
var out := -1.0
var angle := 0.0        ## radianer från rakt ner, positivt åt höger
var omega := 0.0        ## vinkelfart, radianer per sekund
var rider: Node2D = null
## Sant medan han siktar: pendeln står stilla och farten väntar i hoppet.
var frozen := false

var _cooldown := 0.0

func _ready() -> void:
	add_to_group("swing")

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	# En fast stång rör sig inte av sig själv; bara den som hänger i den gör det.
	if not frozen and (kind == Kind.VINE or rider != null):
		omega += -(Settings.rb_gravity / radius()) * sin(angle) * delta
		omega -= omega * Settings.swing_damping * delta
		angle += omega * delta
	if rider != null:
		rider.global_position = seat()
		rider.velocity = tangent() * omega * radius()
	queue_redraw()

## Punkten han svänger runt.
func pivot() -> Vector2:
	return global_position + (Vector2(out * length, 0.0) if kind == Kind.BAR else Vector2.ZERO)

## Avståndet från upphängningen ut till honom.
func radius() -> float:
	return BAR_HOLD if kind == Kind.BAR else length

## Där han sitter just nu.
func seat() -> Vector2:
	return pivot() + Vector2(sin(angle), cos(angle)) * radius()

## Var man får tag: stången griper man var man än når den, lianen i dess ände.
func grip() -> Vector2:
	return pivot() if kind == Kind.BAR else seat()

## Riktningen han far iväg i om han släpper nu: vinkelrätt mot armen.
func tangent() -> Vector2:
	return Vector2(cos(angle), -sin(angle))

## Hur nära greppet han måste komma. Det är ett tillgänglighetsvärde lika mycket
## som ett fysikvärde: den som inte kan styra i luften ska ändå få tag i stången,
## och en radie i storleksordningen hans egen kropp är skillnaden mellan en
## mekanik som går att använda och en som bara ser bra ut.
static func grab_radius() -> float:
	return Settings.swing_grab_radius

func can_grab() -> bool:
	return rider == null and _cooldown <= 0.0

## De två greppen skiljer sig, och skillnaden är hela poängen med att ha båda.
##
## **Lianen** är ett rep som redan hänger där det hänger. Han får det grepp
## geometrin ger honom: bara farten längs banan följer med, resten tar
## upphängningen. Kommer han in i repets riktning tappar han nästan allt, kommer
## han in tvärs igenom botten av svängen behåller han allt.
##
## **Stången** hakar han benen över, och han hakar den på den sida han passerar.
## Alltså sätter han sig själv där farten redan pekar rätt — vinkelrätt mot
## stången — och behåller den. Stången blir en riktningsväxel: lika mycket fart
## ut som in, men riktningen bestämmer han genom att välja när han släpper.
## Att den alltid bevarar farten är ett designval, inte en fysikalisk självklarhet:
## en stel länk hade kastat bort den del av rörelsen som pekar rakt in i fästet,
## och mätt blev det 8 % kvar av en rak inflygning. En mekanik som straffar den
## som träffar för rakt hör inte hemma i det här spelet.
func grab(body: Node2D) -> void:
	rider = body
	frozen = false
	if kind == Kind.BAR:
		angle = _hook_angle(body.velocity)
	else:
		angle = _angle_of(body.global_position)
	omega = body.velocity.dot(tangent()) / radius()
	body.global_position = seat()

## Var runt stången benen hakar fast: vinkelrätt mot farten, på den sida som
## hamnar närmast rakt under. Då är hela farten redan tangentiell.
func _hook_angle(v: Vector2) -> float:
	if v.length() < 1.0:
		return 0.0
	var d := v.normalized()
	var a := Vector2(-d.y, d.x)
	var b := Vector2(d.y, -d.x)
	var pick := a if a.y > b.y else b
	return atan2(pick.x, pick.y)

func release() -> Vector2:
	var out_velocity := tangent() * omega * radius()
	rider = null
	frozen = false
	_cooldown = REGRAB_DELAY
	return out_velocity

## Vinkeln från upphängningen ner till en punkt, mätt från rakt ner.
func _angle_of(point: Vector2) -> float:
	var offset := point - pivot()
	if offset.length() < 0.001:
		return angle
	return atan2(offset.x, offset.y)

func _draw() -> void:
	var p := pivot() - global_position
	if kind == Kind.BAR:
		# Bara greppet självt syns. Fästet och stången ut ur väggen är borta med
		# flit: det man behöver läsa av är punkten han svänger runt, inte hur den
		# sitter fast.
		draw_circle(p, 7.0, Palette.GROUND_EDGE)
	else:
		# Lianen ritas som korta segment som hänger efter i svängen, så att den
		# ser mjuk ut. Den räknas fortfarande som en styv pendel — det syns bara
		# på repet, inte på fysiken.
		var reach := radius() - HOLD_ABOVE
		var points := PackedVector2Array()
		for i in 9:
			var t := float(i) / 8.0
			var a := angle * (0.35 + 0.65 * t)
			points.append(Vector2(sin(a), cos(a)) * (reach * t))
		draw_polyline(points, Palette.GROUND_EDGE, 5.0)
		draw_circle(Vector2.ZERO, 7.0, Palette.GROUND_EDGE)
