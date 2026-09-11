class_name Levels
extends RefCounted
## Banorna som data.
##
## Varje bana är en ordbok med golv, ramper, väggar, lådor och startpunkter.
## Att hålla dem som data i stället för som scener gör att panelen kan byta bana
## direkt, och att en ny testbana är ett par rader — vilket är hela poängen så
## länge vi bygger i gråbox.

const GROUND_Y := 640.0

## Klättringen först: den är den enda banan som är en *bana* och inte en
## verkstad, och den som öppnar spelet utan att veta något ska möta något att
## klara, inte ett testlabb. Ordningen är också vad panelens rullgardin och F3
## stegar igenom.
static func names() -> Array:
	return ["Klättringen", "Lekplatsen", "Rullbanan", "Verkstaden", "Fienderna"]

static func build(index: int) -> Dictionary:
	match index:
		1:
			return _playground()
		2:
			return _roll_test()
		3:
			return _workshop()
		4:
			return _enemies()
		_:
			return _climb()

# ---------------------------------------------------------------- geometri

## Rak ramp som stiger åt höger, angiven i grader.
static func ramp(x0: float, width: float, degrees: float) -> PackedVector2Array:
	var h := width * tan(deg_to_rad(degrees))
	return PackedVector2Array([
		Vector2(x0, GROUND_Y), Vector2(x0 + width, GROUND_Y), Vector2(x0 + width, GROUND_Y - h)])

## Böjd ramp. `concave` vänder på kurvan: falskt ger en hoppbacke som planar ut
## nedtill, sant ger en kvartspipa som blir brantare mot toppen.
static func curve(x0: float, width: float, height: float, concave: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var t := float(i) / float(steps)
		var h := (1.0 - sqrt(maxf(0.0, 1.0 - t * t))) if concave else (t * t)
		pts.append(Vector2(x0 + t * width, GROUND_Y - h * height))
	pts.append(Vector2(x0 + width, GROUND_Y))
	pts.append(Vector2(x0, GROUND_Y))
	return pts

## Skål: en parabolisk dal med botten i marknivå och väggar som reser sig.
## Här ser man rullmotståndet direkt — han pendlar och tappar höjd för varje
## vända, precis som en kula i en skål ska göra.
static func bowl(x0: float, width: float, depth: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 26
	var half := width * 0.5
	for i in steps + 1:
		var x := x0 + width * float(i) / float(steps)
		var k := (x - (x0 + half)) / half
		pts.append(Vector2(x, GROUND_Y - depth * k * k))
	pts.append(Vector2(x0 + width, GROUND_Y + 260.0))
	pts.append(Vector2(x0, GROUND_Y + 260.0))
	return pts

## Mjuk puckel att rulla över.
static func hump(x0: float, width: float, height: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		var t := float(i) / float(steps)
		pts.append(Vector2(x0 + t * width, GROUND_Y - height * sin(t * PI)))
	pts.append(Vector2(x0 + width, GROUND_Y))
	pts.append(Vector2(x0, GROUND_Y))
	return pts

# ---------------------------------------------------------------- lekplatsen

static func _playground() -> Dictionary:
	var right := 4700.0
	var cube := Vector2(46, 40)
	var small := Vector2(24, 22)
	var plank := Vector2(260, 18)
	var pillar := Vector2(48, 92)
	var crates: Array = []

	# Lös småsten direkt vid starten, så att det första RB går in i reagerar.
	for i in 8:
		crates.append({"pos": Vector2(300 + i * (small.x + 6), GROUND_Y - small.y * 0.5), "size": small})

	# Pyramid, bas fem — rasar snyggt om man träffar den snett underifrån.
	for row in 5:
		for i in 5 - row:
			crates.append({"pos": Vector2(3000 + i * (cube.x + 2) + row * (cube.x + 2) * 0.5,
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	# Enkelbreda torn i tre höjder. Att landa på toppen av en smal stapel är
	# det svåraste fallet för kollisionerna, så de får stå kvar som testfall.
	var towers := {2900: 4, 3320: 6, 3620: 9}
	for x in towers:
		for row in int(towers[x]):
			crates.append({"pos": Vector2(float(x), GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)),
				"size": cube})

	# Mur, fyra gånger tre.
	for col in 4:
		for row in 3:
			crates.append({"pos": Vector2(3420 + col * (cube.x + 2),
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	# Bro: plankor med överhäng på två breda pelare.
	for side in [0.0, 1.0]:
		crates.append({"pos": Vector2(4040 + side * 200.0, GROUND_Y - pillar.y * 0.5), "size": pillar})
	for layer in 2:
		crates.append({"pos": Vector2(4140, GROUND_Y - pillar.y - plank.y * 0.5 - 3.0
			- layer * (plank.y + 3)), "size": plank})

	# Stapel högst upp i trappan, att landa på uppifrån.
	for row in 3:
		for i in 2:
			crates.append({"pos": Vector2(4390 + i * (cube.x + 2),
				340 - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	return {
		"name": "Lekplatsen",
		"right_edge": right,
		"floors": [
			Rect2(-60, GROUND_Y, right + 60.0, 320),
			Rect2(1560, 520, 260, 26),
			Rect2(1900, 420, 240, 26),
			Rect2(2240, 330, 220, 26),
			Rect2(3850, 540, 200, 26),
			Rect2(4100, 440, 200, 26),
			Rect2(4330, 340, 240, 26),
		],
		"walls": [Rect2(-120, 240, 60, 400), Rect2(right, 200, 60, 440)],
		"ramps": [
			ramp(650, 330, 18.4),
			ramp(1060, 230, 31.3),
			curve(2560, 300, 150, false),
			curve(3700, 260, 210, true),
		],
		"crates": crates,
		"spawns": [
			{"name": "Start", "pos": Vector2(150, GROUND_Y - 60)},
			{"name": "Ramper", "pos": Vector2(700, GROUND_Y - 60)},
			{"name": "Hoppbacke", "pos": Vector2(2400, GROUND_Y - 60)},
			{"name": "Trappan", "pos": Vector2(1600, 470)},
			{"name": "Lådor", "pos": Vector2(2850, GROUND_Y - 60)},
			{"name": "Bygget", "pos": Vector2(3900, GROUND_Y - 60)},
		],
	}

# ---------------------------------------------------------------- rullbanan

## En bana som bara handlar om rullfysiken.
##
## Fyra stationer: en trappa av lutningar där man ser exakt var benen åker in
## och var fästet släpper, en skål där rullmotståndet blir synligt som en
## pendling som dör ut, en lång utrullning som visar hur väl rörelsemängden
## bevaras, och puckelbanan som visar vad ojämn mark gör med farten.
static func _roll_test() -> Dictionary:
	var right := 7000.0
	var crates: Array = []
	var cube := Vector2(46, 40)

	# Målet längst bort: allt som är kvar av farten hamnar här.
	for row in 4:
		for i in 2:
			crates.append({"pos": Vector2(4150 + i * (cube.x + 2),
				GROUND_Y - cube.y * 0.5 - row * (cube.y + 2)), "size": cube})

	var ramps: Array = []
	# Vinkeltrappan: 15, 25, 35, 41, 45 och 55 grader bredvid varandra. De tre
	# sista ligger tätt med flit — de spänner över de två gränserna. Vid 41
	# står han kvar på benen men orkar inte hela vägen upp (klättergränsen går
	# vid 40 med grundvärdena), vid 45 åker benen in. Se docs/METRICS.md.
	var angles := [15.0, 25.0, 35.0, 41.0, 45.0, 55.0]
	for i in angles.size():
		ramps.append(ramp(140.0 + i * 250.0, 190.0, angles[i]))
	# Skålen.
	# Väggarna når 58 grader, alltså långt över vad benen klarar: i skålen
	# rullar han, och rullmotståndet blir synligt som en pendling som dör ut.
	ramps.append(bowl(1620, 840, 340))
	# Puckelbanan — små ojämnheter som bara skakar om farten.
	for i in 4:
		ramps.append(hump(2760.0 + i * 210.0, 190.0, 46.0 + i * 10.0))
	# Kullarna: samma skala som skålen, fast åt andra hållet. Flankerna når 53
	# grader, alltså långt över vad benen klarar — han rullar nedför, tappar fart
	# uppför nästa, och man ser rörelsemängden räcka eller inte räcka.
	for i in 3:
		ramps.append(hump(4500.0 + i * 820.0, 760.0, 320.0))

	return {
		"name": "Rullbanan",
		"right_edge": right,
		"floors": [
			Rect2(-60, GROUND_Y, right + 60.0, 320),
			# Avsatsen man släpps från för den långa utrullningen.
			Rect2(3640, 300, 260, 26),
		],
		"walls": [Rect2(-120, 240, 60, 400), Rect2(right, 180, 60, 460)],
		"ramps": ramps,
		"crates": crates,
		"spawns": [
			{"name": "Vinkeltrappan", "pos": Vector2(160, GROUND_Y - 60)},
			{"name": "41 grader", "pos": Vector2(900, GROUND_Y - 60)},
			{"name": "45 grader", "pos": Vector2(1150, GROUND_Y - 60)},
			{"name": "55 grader", "pos": Vector2(1400, GROUND_Y - 60)},
			{"name": "Skålen", "pos": Vector2(1700, 320)},
			{"name": "Pucklarna", "pos": Vector2(2700, GROUND_Y - 60)},
			{"name": "Utrullningen", "pos": Vector2(3700, 250)},
			{"name": "Kullarna", "pos": Vector2(4420, GROUND_Y - 60)},
		],
	}

# ---------------------------------------------------------------- verkstaden

## Banan där nya mekaniker provas.
##
## Ingenting här är bestämt som en del av spelet. Verkstaden finns för att kunna
## känna på en mekanik i spelets riktiga fysik innan någon bestämmer sig — det är
## billigare att bygga en station här än att argumentera om den (docs/DECISIONS.md 20).
##
## Två saker styr formen. Studsmattorna ligger *infällda i marken*, för en matta
## som svävar ovanför den blir bara en kant att vända vid. Och stängerna sitter
## fast och sticker ut ur hängande pelare, som i konceptskiss 05 — pelarna hänger
## uppifrån och slutar en bra bit över marken, så att gången under är fri.
static func _workshop() -> Dictionary:
	var right := 5200.0
	var mats := [
		{"pos": Vector2(700, GROUND_Y), "width": 240.0},    ## hoppa ner på den
		{"pos": Vector2(1420, GROUND_Y), "width": 280.0},   ## under avsatsen
		{"pos": Vector2(4300, GROUND_Y), "width": 240.0},   ## kedjans första led
	]

	# Golvet delas upp så att mattornas dukar blir marken där de ligger.
	var floors: Array = []
	var edge := -60.0
	for mat: Dictionary in mats:
		var pos: Vector2 = mat["pos"]
		var half: float = float(mat["width"]) * 0.5
		floors.append(Rect2(edge, GROUND_Y, pos.x - half - edge, 320))
		edge = pos.x + half
	floors.append(Rect2(edge, GROUND_Y, right - edge, 320))

	# Trappan upp till avsatsen, så att man alltid kan ta sig upp igen.
	floors.append(Rect2(900, 520, 130, 22))
	floors.append(Rect2(1080, 430, 130, 22))
	floors.append(Rect2(1300, 350, 240, 24))

	# Avsats att landa på efter stängerna, och målet efter lianerna.
	floors.append(Rect2(2650, 430, 240, 24))
	floors.append(Rect2(4020, 360, 240, 24))

	var walls: Array = [Rect2(-120, 240, 60, 400), Rect2(right, 180, 60, 460)]

	var swings: Array = []
	# Stängerna hänger fritt: bara greppen, inga pelare omkring dem. 185 px över
	# marken, precis inom räckhåll för ett hopp rakt upp.
	for x: float in [1860.0, 2360.0, 4520.0]:
		swings.append({"pos": Vector2(x, 455), "length": 0.0, "kind": "bar"})
	# Lianerna: nästan tre gånger så långa, alltså märkbart långsammare.
	for i in 3:
		swings.append({"pos": Vector2(2950.0 + i * 420.0, 130), "length": 330.0,
			"kind": "vine", "angle": 0.0})

	return {
		"name": "Verkstaden",
		"right_edge": right,
		"floors": floors,
		"walls": walls,
		"ramps": [],
		"crates": [],
		"trampolines": mats,
		"swings": swings,
		"spawns": [
			{"name": "Mattan", "pos": Vector2(360, GROUND_Y - 60)},
			{"name": "Avsatsen", "pos": Vector2(1400, 300)},
			{"name": "Stängerna", "pos": Vector2(1800, GROUND_Y - 60)},
			{"name": "Lianerna", "pos": Vector2(2800, GROUND_Y - 60)},
			{"name": "Kedjan", "pos": Vector2(4150, GROUND_Y - 60)},
		],
	}

# ---------------------------------------------------------------- fienderna

## Banan där fienderna provas.
##
## Två sorter, och de lär ut var sin sak — men de hålls isär tills var och en
## sitter för sig. Första halvan är bara **blå**: de går på marken, dör av att
## RB kommer flygande, och skadar den som går eller rullar in i dem. Samma
## fiende betyder alltså olika saker beroende på vad han själv gör, vilket är
## den enklaste regel ett barn kan läsa av på egen hand.
##
## Andra halvan är bara **röd**: de flyger fram och tillbaka längs en sinusvåg,
## bryr sig inte om att bli hoppade på och skadar vid varje beröring. Där finns
## inga avsatser i vägen — vågen ska synas hel, och den enda vägen förbi är
## lasern.
static func _enemies() -> Dictionary:
	var right := 5200.0
	var enemies: Array = []

	# Blå halvan. Först en ensam att hoppa på, sedan tre i rad — kedjan.
	enemies.append({"pos": Vector2(900, GROUND_Y - 40), "kind": "blue"})
	for i in 3:
		enemies.append({"pos": Vector2(1500.0 + i * 240.0, GROUND_Y - 40), "kind": "blue"})
	enemies.append({"pos": Vector2(2400, GROUND_Y - 40), "kind": "blue"})

	# Röda halvan: fritt luftrum, inga avsatser. Först en ensam i ögonhöjd, sedan
	# två högre upp med olika våglängd så att man ser att banan är en våg.
	enemies.append({"pos": Vector2(3200, 420), "kind": "red", "span": 300.0, "wave": 70.0})
	enemies.append({"pos": Vector2(3950, 330), "kind": "red", "span": 380.0, "wave": 110.0})
	enemies.append({"pos": Vector2(4700, 400), "kind": "red", "span": 240.0, "wave": 140.0})

	return {
		"name": "Fienderna",
		"right_edge": right,
		"floors": [
			Rect2(-60, GROUND_Y, right + 60.0, 320),
			# Avsatser hör till den blå halvan: något att möta dem från ovanifrån.
			Rect2(1180, 470, 200, 24),
			Rect2(2050, 430, 200, 24),
		],
		"walls": [Rect2(-120, 240, 60, 400), Rect2(right, 180, 60, 460)],
		"ramps": [ramp(700.0, 200.0, 26.0)],
		"crates": [],
		"enemies": enemies,
		"spawns": [
			{"name": "Start", "pos": Vector2(200, GROUND_Y - 60)},
			{"name": "Kedjan", "pos": Vector2(1300, GROUND_Y - 60)},
			{"name": "Röda halvan", "pos": Vector2(2900, GROUND_Y - 60)},
			{"name": "Höga vågen", "pos": Vector2(3700, GROUND_Y - 60)},
			{"name": "Sista", "pos": Vector2(4450, GROUND_Y - 60)},
		],
	}

# ---------------------------------------------------------------- klättringen

## Backen ner från platån: brant redan vid krönet och utplanande mot avsatsen.
##
## Formen är vald av två skäl, och båda är fysik och inte utseende. Lutningen vid
## krönet är (höjdskillnaden · π/2) / bredden, alltså drygt 50° med måtten nedan —
## med flit över benens gräns på 43°, så att han *rullar* från första ögonblicket.
## En backe som börjar flackt går han i stället ner för, och en gående RB är en
## kapsel som kan haka i hörnen mellan segmenten: mätt blev han stående på 40,8°
## med full gångfart och kom ingenstans. Som boll är han en cirkel, och en cirkel
## rullar över samma hörn utan att märka dem.
##
## Nedtill planar den ut, så att farten pekar vågrätt när han lämnar avsatsen.
## Ett hårt hörn där hade kostat en del av farten i själva kröken.
static func _slope(from: Vector2, to: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		pts.append(Vector2(lerpf(from.x, to.x, t), from.y + (to.y - from.y) * sin(t * PI * 0.5)))
	return pts

## Skålen: avsatsen som rullar över i en backe, en rundad botten och en uppstuds.
##
## Formen är inte pynt utan tre krav ur fysiken:
##
## 1. **Avsatsen övergår i backen.** Han kommer inte gående — RB går aldrig ner
##    för något brantare än ungefär 33°, och kantskyddet vänder honom. Men den
##    som *rullar* lyder inget kantskydd, och rullar han över ett krön med stor
##    radie sitter han kvar i ytan hela vägen ner. Ett hopp ner i skålen provades
##    först och visade sig omöjligt att bygga: hur fort han råkade rulla avgjorde
##    var han landade, och landade han för långt ner slog han i botten och tappade
##    allt. Med ett krön i stället spelar farten ingen roll för vägen, bara för
##    hur högt han till slut kastas.
## 2. **Botten är en båge och inte ett hörn.** Ett hörn hade kastat bort den del
##    av farten som pekar in i den nya ytan — i 45° är det 71 % av allt han har.
## 3. **Uppstudsen är konkav.** En konkav yta släpper honom aldrig; den trycker
##    honom in i sig. Han följer den alltså tills bollen tappar greppet vid
##    Settings.roll_max_slope (62°) och kastas ut i just den riktningen. Det är
##    hela mekaniken: farten han samlat i backen pekar *uppåt* när han lämnar
##    rampen. Ett hopp kan aldrig göra det åt honom — hoppkraften läggs till den
##    fart han redan har, och står han still finns ingen uppåtfart att lägga den
##    till. Därför går flaggan bara att nå via rampen.
## En cirkelbåge, med gott om punkter. Antalet är inte en smaksak: krönet mäts
## av spelet som hur mycket underlagets lutning ändrar sig medan han rör sig, och
## med glesa punkter kommer hela ändringen i ett enda hopp. Då ser en mjuk kurva
## ut som ett tvärt hörn, och han släpper ytan i onödan — mätt lyfte han från ett
## krön med radien 400 px i 665 px/s, där den verkliga gränsen ligger vid 190.
##
## `crest` vänder på bågen: falskt ger en dal med medelpunkten
## ovanför ytan, sant ett krön med medelpunkten under.
static func _arc(center: Vector2, radius: float, from_deg: float, to_deg: float,
		steps: int, crest := false) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var flip := -1.0 if crest else 1.0
	for i in steps + 1:
		var phi := deg_to_rad(lerpf(from_deg, to_deg, float(i) / float(steps)))
		pts.append(center + Vector2(sin(phi), cos(phi) * flip) * radius)
	return pts

## Gör en yta till en solid remsa med jämn tjocklek. Skålen är alltså en ramp och
## inte ett massivt berg: under den går det att gå, och det är där den som missar
## hamnar (princip 4 — aldrig en återvändsgränd).
static func _ramp_body(raw: PackedVector2Array, thickness: float) -> PackedVector2Array:
	# Dubblettpunkter måste bort först. En båge som börjar där föregående del
	# slutade ger ett segment med längden noll, och runt det viker undersidan
	# tillbaka över sig själv — polygonen korsar sig själv och motorn vägrar
	# bygga den. Felet syns bara som "Convex decomposing failed".
	var surface := PackedVector2Array()
	for p in raw:
		if surface.is_empty() or surface[surface.size() - 1].distance_to(p) > 0.5:
			surface.append(p)
	var out := PackedVector2Array(surface)
	# Undersidan läggs vinkelrätt mot ytan och inte rakt ner. Rakt ner fungerar
	# bara så länge ytan är flack: i 62° flyttar 110 px nedåt kanten bara 52 px
	# åt sidan, och då korsar undersidan ovansidan — polygonen blir omöjlig att
	# dela upp och motorn vägrar bygga den.
	for i in range(surface.size() - 1, -1, -1):
		# Ändpunkterna får en lodrät kant. En vinkelrät kant på en 45-graders
		# läpp lämnar en liten hylla utanför rampen, och mätt blev RB stående på
		# den i stället för att falla ner — en hylla som inte syns är en
		# återvändsgränd som inte går att förstå.
		if i == 0 or i == surface.size() - 1:
			out.append(surface[i] + Vector2(0.0, thickness))
			continue
		var tangent := (surface[i + 1] - surface[i - 1]).normalized()
		out.append(surface[i] + Vector2(-tangent.y, tangent.x) * thickness)
	return out

## Överhänget vid starten: en balkong vars undersida svänger ner till marken i en
## kvartscirkel. Den stänger vägen åt vänster utan att se ut som en osynlig mur,
## och den är samtidigt skyddsnätet för den som missar stången ovanför: den som
## faller landar på balkongen i stället för på marken.
static func _overhang(foot: float, out_to: float, top: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(foot, top), Vector2(out_to, top)])
	var steps := 12
	for i in range(1, steps + 1):
		var a := PI * 0.5 * float(i) / float(steps)
		pts.append(Vector2(
			out_to - (out_to - foot) * sin(a), top + (GROUND_Y - top) * (1.0 - cos(a))))
	return pts

## Banan ur konceptskissen: tre farleder ovanpå varandra, och målet är flaggan.
##
## Nedersta farleden går åt höger längs marken, den mellersta tillbaka åt vänster
## genom stänger och lianer, och den översta åt höger igen längs avsatserna till
## platån — därifrån rullar han ner för backen och skjuter ifrån mot flaggtornet.
## Sicksacken är hela poängen: samma bana används tre gånger i tre höjder, och
## varje varv byter mekanik (hoppa, svinga, rulla).
##
## Missar han ett hopp faller han alltid ner i en farled han kan ta sig vidare
## från — marken bär hela banan, det stora blocket ligger under gapet till tornet
## och balkongen under stången. Ingen väg kan alltså köra fast (princip 4).
static func _climb() -> Dictionary:
	var right := 5400.0

	# Avsatsen och skålen är en och samma yta: plant, krön, backe, botten, uppstuds.
	# Krönets radie är räknad och inte vald: han släpper ytan när v²/r går över
	# tyngden plus markfästet (1550), och han kommer in i som mest ~800 px/s —
	# alltså krävs minst 800²/1550 = 413 px. 700 ger marginal även om någon
	# skruvar upp hoppkraften i panelen.
	var surface := PackedVector2Array([Vector2(2400.0, -380.0), Vector2(2800.0, -380.0)])
	surface.append_array(_arc(Vector2(2800.0, 320.0), 700.0, 0.0, 42.0, 60, true))
	surface.append_array(_arc(Vector2(3841.0, 60.0), 190.0, -42.0, 45.0, 30))
	surface.append(Vector2(4549.0, -380.0))

	return {
		"name": "Klättringen",
		"right_edge": right,
		"top_edge": -640.0,
		"floors": [
			Rect2(100, GROUND_Y, right - 40.0, 320),
			# Nedersta farleden: tre trappsteg och två avsatser upp till blocket.
			Rect2(560, 577, 190, 63),
			Rect2(900, 577, 190, 63),
			Rect2(1240, 577, 190, 63),
			Rect2(1530, 488, 190, 60),
			Rect2(1830, 399, 190, 60),
			# Blocket: en fribärande avsats, inte ett berg. Den som missar ett hopp
			# landar på den och kan ta sig vidare via stängerna — och under den
			# löper marken hela vägen, så ingen väg kan köra fast.
			Rect2(2120, 310, 680, 110),
			# Översta farleden.
			Rect2(560, -250, 190, 90),
			Rect2(880, -340, 190, 70),
			Rect2(1200, -430, 190, 70),
			# Platån. Krönet är ett avstamp: härifrån hoppar han ner på avsatsen.
			Rect2(1520, -520, 830, 340),
			# Flaggtornet. Toppen ligger 680 px över blocket och 1200 px från
			# avsatsen: dubbelhoppet når 338, längsta hopp 346.
			Rect2(4640, -430, 460, 250),
			Rect2(4900, -180, 200, 820),
		],
		"walls": [Rect2(120, -150, 310, 790)],
		"ramps": [_overhang(295.0, 980.0, 78.0), _ramp_body(surface, 70.0)],
		"crates": [],
		"swings": [
			{"pos": Vector2(480, -130), "kind": "bar", "length": 0.0},
			{"pos": Vector2(1250, -120), "kind": "vine", "length": 290.0},
			{"pos": Vector2(1500, -120), "kind": "vine", "length": 290.0},
			{"pos": Vector2(1740, 160), "kind": "bar", "length": 0.0},
			{"pos": Vector2(1960, 170), "kind": "bar", "length": 0.0},
		],
		"flag": Vector2(4820, -430),
		"spawns": [
			{"name": "Start", "pos": Vector2(400, 580)},
			{"name": "Trappan", "pos": Vector2(1590, 420)},
			{"name": "Stängerna", "pos": Vector2(2200, 250)},
			{"name": "Balkongen", "pos": Vector2(600, 20)},
			{"name": "Pelartoppen", "pos": Vector2(250, -210)},
			{"name": "Platån", "pos": Vector2(2000, -580)},
			{"name": "Avsatsen", "pos": Vector2(2500, -440)},
			{"name": "Flaggan", "pos": Vector2(4740, -490)},
		],
	}
