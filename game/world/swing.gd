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
## Hur långt upp mot fästet man som minst kan greppa en lian.
const VINE_MIN_HOLD := 70.0
## Hur mycket benen ger efter för centrifugalkraften när han snurrar fort.
const STRETCH := 20.0
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
## Var på armen benen är hakade, räknat från fästet. På en stång är det fästet
## självt; på en lian den punkt av repet han tog tag i — högt upp ger en kort,
## snabb pendel, långt ner en lång och långsam. Det är hela skillnaden mellan två
## grepp i samma lian. Kroppen hänger alltid BAR_HOLD nedanför den punkten, precis
## som i stången: han hänger *i benen*, inte med kroppen mitt i repet.
var hook := 0.0
## Vad benen sträckt sig till just nu, av centrifugalkraften.
var _stretch := 0.0

var _cooldown := 0.0

func _ready() -> void:
	add_to_group("swing")

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	# En fast stång rör sig inte av sig själv; bara den som hänger i den gör det.
	if not frozen and (kind == Kind.VINE or rider != null):
		_apply_stretch(delta)
		omega += -(Settings.rb_gravity / radius()) * sin(angle) * delta
		omega -= omega * Settings.swing_damping * delta
		angle += omega * delta
		# Vinkeln hålls inom ett varv. Utan det räknade den bara uppåt — mätt
		# 1243 grader efter några sekunders snurrande — och då blev repet ritat
		# som en härva och hittade aldrig tillbaka till sitt viloläge.
		angle = wrapf(angle, -PI, PI)
	if rider != null:
		rider.global_position = seat()
		rider.velocity = tangent() * omega * radius()
	queue_redraw()

## Benen ger efter för centrifugalkraften.
##
## Ju fortare han snurrar desto hårdare dras kroppen utåt, och benen sträcks. Den
## uttänjning som centrifugalkraften ger jämfört med tyngden är ω²r/g, alltså
## exakt det talet — och när radien ändras bevaras rörelsemängdsmomentet L = r²ω,
## precis som när en konståkare drar in armarna. Sträcker han ut sig går varvet
## alltså långsammare, drar han in sig går det fortare, av sig självt.
func _apply_stretch(delta: float) -> void:
	if rider == null:
		_stretch = maxf(0.0, _stretch - delta * 60.0)
		return
	var base := maxf(hook + BAR_HOLD, 1.0)
	var pull := omega * omega * base / maxf(Settings.rb_gravity, 1.0)
	var target := clampf(pull, 0.0, 1.0) * STRETCH * Settings.swing_stretch
	var before := radius()
	_stretch = lerpf(_stretch, target, minf(1.0, delta * 6.0))
	var after := radius()
	if after > 0.01 and absf(after - before) > 0.001:
		omega *= (before * before) / (after * after)

## Punkten han svänger runt.
func pivot() -> Vector2:
	return global_position + (Vector2(out * length, 0.0) if kind == Kind.BAR else Vector2.ZERO)

## Avståndet från upphängningen ner till hans kropp: dit benen är hakade, plus
## en kroppslängd till.
func radius() -> float:
	return hook + BAR_HOLD + _stretch

## Riktningen ut från fästet just nu.
func arm() -> Vector2:
	return Vector2(sin(angle), cos(angle))

## Där benen är hakade.
func hook_point() -> Vector2:
	return pivot() + arm() * hook

## Där kroppen hänger just nu.
func seat() -> Vector2:
	return pivot() + arm() * radius()

## Var benen sitter fast — och därmed vad de ritas mot. Stången griper man var man
## än når den, lianen var som helst längs repet.
func grip() -> Vector2:
	return hook_point()

## Närmaste greppunkt på repet till en given plats, och hur långt ut den ligger.
func grab_point(from: Vector2) -> Dictionary:
	if kind == Kind.BAR:
		return {"point": pivot(), "hook": 0.0}
	var along := clampf((from - pivot()).dot(arm()), VINE_MIN_HOLD, length)
	return {"point": pivot() + arm() * along, "hook": along}

## Hur nära repet han är som närmast — grepp om lianen mäts mot hela repet, inte
## bara mot dess ände. Det är det som gör att var man tar tag betyder något.
func distance_to_rope(from: Vector2) -> float:
	return from.distance_to((grab_point(from)["point"] as Vector2))

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
	_stretch = 0.0
	if kind == Kind.BAR:
		hook = 0.0
		angle = _hook_angle(body.velocity)
	else:
		# Lianen: han hakar benen där han når repet, och kroppen hamnar nedanför.
		hook = float(grab_point(body.global_position)["hook"])
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
	hook = 0.0
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
		# Repet ritas i sin fulla längd även när han hänger en bit upp på det: det
		# är ju hela repet som finns där, och nedanför honom dinglar resten.
		var points := PackedVector2Array()
		for i in 13:
			var t := float(i) / 12.0
			var a := angle * (0.35 + 0.65 * t)
			points.append(Vector2(sin(a), cos(a)) * (length * t))
		draw_polyline(points, Palette.GROUND_EDGE, 5.0)
		draw_circle(Vector2.ZERO, 7.0, Palette.GROUND_EDGE)
