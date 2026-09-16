# Mått

Allt här är **mätt**, inte antaget: siffrorna kommer ur körningar med spelets
riktiga fysik vid grundvärdena, inte ur formler på ett papper. Mätningen gjordes
2026-09-04, efter att benens gräns satts till 43°.

Ingenting här är låst. Varje siffra hänger på reglage som ska fortsätta gå att
skruva på (docs/DECISIONS.md 15) — meningen med att skriva ner dem är att kunna
bygga banor som håller, och att märka när en ändring i panelen gör en gammal
bana ospelbar.

## Kroppen

| | px |
| --- | --- |
| Stående kapsel | 70 hög, 44 bred |
| Boll (kapseln indragen) | 44 i diameter |

## Backar

| Lutning | Vad som händer |
| --- | --- |
| 0–42° | Går uppför hela vägen |
| 43° och brantare | Benen åker in, han rullar |
| Över 62° | Bollen tappar greppet och faller |

Benen har dessutom en högsta takt: **1,8 gånger gångfarten, alltså 234 px/s**.
Kommer han in fortare än så rullar han, oavsett lutning. Det märks mest vid
landningar — mätt på kullens fot landade han i 40° med 582 px/s och blev
stående, och benen åt upp hela farten på en halv sekund. Nu fortsätter han som
boll och behåller den. Han reser sig igen vid 0,75 av samma takt, så han inte
fladdrar precis på gränsen.

Det fanns tidigare ett spann på 41–42° där han stod kvar på fötterna men gled
bakåt: klättergränsen låg på 40 medan benen satt kvar till 43. Mätt 93 bildrutor
i det läget på en 42-gradersramp — varken gående eller rullande. Två saker tog
bort det. Gångaccelerationen är 980 i stället för 900, vilket lyfter
klättergränsen till 44° så att det är benen som bestämmer. Och benen ger vika av
sig själva så snart backen drar honom bakåt fortare än de kan driva honom framåt,
vad reglagen än står på — så spannet kan inte uppstå igen.

Klättergränsen är ingen inställning utan en följd av två andra:

    brantaste backen han orkar = asin(gångacceleration / gravitation)

Med grundvärdena 980 och 1400 blir det 44,4°, alltså strax **över** benens gräns
på 43. Det är med flit: då är det benen som sätter gränsen för var rullningen
börjar, inte kraften, och det finns inget spann däremellan. Ändrar man tempot
flyttar sig klättergränsen, och panelens *Rullning*-flik räknar om och skriver
ut den under reglaget för benens gräns.

## Hoppet

Uppmätt från plan mark, utan fart med sig, vid grundvärdena (kraft 700,
gravitation 1400):

| Vinkel | Höjd | Längd | Tid i luften |
| --- | --- | --- | --- |
| 90° | 169 px | 0 | 1,00 s |
| 75° | 158 px | 172 px | 0,95 s |
| 60° | 126 px | 298 px | 0,85 s |
| 45° | 83 px | 346 px | 0,70 s |
| 30° | 41 px | 303 px | 0,50 s |

Längsta hoppet är alltså 346 px, högsta 169 px, och de går inte att få
samtidigt. Med dubbelhoppet påslaget kan andra hoppet läggas ovanpå det första.

## Kanter

En boll som rullar ut över en avsats behåller **99 %** av sin fart (mätt: 306
px/s in i kanten, 303 ut ur den) och landar som boll. Tre saker krävdes för
det, och alla tre går att stänga av var för sig i panelen:

* Kanten han lämnar räknas inte som en vägg han kört in i.
* Krönet släpper när farten inte kan följa det — v²/r mot tyngden plus markfästet.
* Att nudda marken på väg ut ur kanten är ingen landning; bara rörelse in i ytan är det.

Innan de tre fanns tappade han 57 % av farten på en vanlig avsats och landade
gående, vilket band honom vid gångfarten 130 px/s.

## Landningar

En landning avgörs av farten från bildrutan **före** kollisionen, inte av den som
står kvar efteråt. Motorns glidning har redan skalat bort komponenten in i ytan
när koden får se den, så läser man den ser varje landning ut som en flykt.

Golvsnäppet — motorns hjälp att följa med nedför en backe utan att lätta — är
avstängt i luften. Med det påslaget drog motorn honom mot kullens flank och
nollade fallfarten, medan spelet fortfarande räknade honom som flygande: han
åkte nedför hela kullen i luftläget, med benen ute, varken gående eller
rullande. Det var felet som syntes när man landade strax efter krönet.

## Väggar

En boll som rullar in i en vägg studsar tillbaka med den andel `Settings.wall_bounce`
säger — 40 % med grundvärdet — och lämnar väggen bildrutan efter träffen. Detsamma
gäller en träff i luften: 500 px/s in ger 200 ut.

Innan farten före kollisionen började användas som beslutsunderlag hände ingetdera.
Motorns glidning skalar bort komponenten in i väggen, så koden såg aldrig någon
träff: en boll i 400 px/s låg kvar mot väggen i **141 bildrutor**, alltså över två
sekunder, och malde ner farten mot rullmotståndet i stället för att studsa. Svept
över 240 sätt att möta samma vägg — olika fart, höjd och infallsvinkel — fastnade
8 av dem förut; efteråt är längsta stillastående 1 bildruta.

Det är samma rotfel som landningen hade: `move_and_slide` skriver om `velocity`
innan koden får se den. Regeln är alltså allmän — **läs alltid farten från före
förflyttningen när ett beslut ska fattas om en kollision**.

## Farten som följer med i hoppet

Hopp på 45° ur en rullning, hoppkraft 700:

| Medföljning | rullar 200 px/s | rullar 500 px/s |
| --- | --- | --- |
| 0 % | 685 px/s (44°) | 685 px/s (44°) |
| 50 % | 764 px/s (39°) | 890 px/s (33°) |
| 100 % (grund) | 847 px/s (35°) | 1114 px/s (27°) |

Ju fortare han rullar, desto flackare och längre blir hoppet — han skjuter ifrån i
stället för att starta om. I luften gäller medföljningen inte.

## Fienderna

| | mätt |
| --- | --- |
| Fyrkantens storlek | 42 × 42 px |
| Gångfart, blå | 70 px/s |
| Rödas flygbana | svep 600 px i sidled (2 × spannet), våg 140 px, toppfart 186 px/s |
| Studs när han landar på en blå | 520 px/s uppåt |
| En träff räknas som anfall efter landning i | 0,12 s (`ATTACK_GRACE`) |
| Skjutsiktet dyker upp när en röd är närmare än | 700 px |
| Skjutsiktets sveptakt | 0,9 svep/s över 0–180° |
| Skjutsiktet saktar ner vid en fiende till | 0,08× takt |
| Laserns räckvidd | 1400 px, stoppas av väggar |
| Osårbar efter en träff | 1,2 s |

Kontrollerat i banan: ett fall på en blå dödar den och ger kedja 1 med 520 px/s uppåt;
att gå in i samma sorts fiende på marken kostar ett hjärta och fienden överlever; en
laser med fri sikt dödar en flygande röd och ger också kedja 1; och en röd bakom en
avsats skyddas av avsatsen — strålen tar stopp i väggen.

### Skjutsiktet saktar ner vid en fiende

En fyrkant är 42 px bred, så på 400 px håll upptar den **6°** av visarens halvvarv. I
full sveptakt betyder det att visaren står på fienden i **1 bildruta** — träffen avgörs
alltså av att trycka på rätt hundradels sekund, vilket är precis den sortens krav spelet
finns till för att slippa.

Därför bromsar visaren in medan den pekar på något som går att skjuta, och tar upp takten
igen när den passerat. Bromsen är full så länge visaren *är* på fienden (fiendens egen
bredd i grader plus 1°) och tonas sedan ut över 6° till full takt. Mätt med RB 400 px
från en flygande röd, antal bildrutor visaren pekade inom fyrkantens bredd:

| inbromsning | bildrutor på mål | tid |
| --- | --- | --- |
| 1,00× (avstängd) | 1 | 0,02 s |
| 0,25× | 4 | 0,07 s |
| 0,12× | 9 | 0,15 s |
| 0,08× (grund) | 14 | 0,23 s |
| 0,06× | 16 | 0,27 s |

Grundvärdet 0,08 ger alltså 0,23 s att trycka på — fjorton gånger så länge som utan
inbromsning. Reglaget står i panelens *Föremål*-flik och 1,00× stänger av det.

En **spets i stället för en platå** var det första försöket: full broms bara i den exakta
mitten och linjär upptrappning utanför. Det mätte 3 bildrutor vid 0,12 mot platåns 9. Det
är samma sak som med anfallsfönstret: det är inte tiden då siktet är *perfekt* som ska
räcka till, det är tiden då ett tryck faktiskt träffar.

Bromsen gäller **bara röda, och bara de som syns i bild**.

*Bara röda*, fast strålen dödar en blå lika gärna: den blå har redan ett svar som inte
kräver att man siktar, nämligen att hoppa på den. Att bromsa för den vore att erbjuda det
svåra svaret på den lätta frågan, och i praktiken hakade visaren upp sig på blå man bara
gick förbi.

*Bara det som syns*, för räckvidden dög inte som gräns: lasern når 1400 px, men vid zoom
1,05 visar en 1280 px bred bild **1219 px av världen**, alltså 610 px åt vardera hållet.
Mer än halva räckvidden ligger utanför skärmen, och där är en inbromsning ingen hjälp
utan en oförklarlig hackning. Gränsen läses ur vyns egen transform och inte ur ett
avstånd, för kameran har utjämning, zoom och gränser vid banans kanter — nära en bankant
är RB inte längre mitt i bilden.

Mätt på plats i Fienderna, en fiende i taget (annars ligger de på rad och en och samma
riktning pekar på flera):

| fiende | avstånd | i bild | broms |
| --- | --- | --- | --- |
| blå | 215 px | ja | 1,00× |
| blå | 278 px | ja | 1,00× |
| blå | 630 px | nej | 1,00× |
| blå | 720 px | nej | 1,00× |
| röd | 281 px | ja | **0,08×** |
| röd | 709 px | ja | **0,08×** |
| röd | 1300 px | nej | 1,00× |

(I headless rapporterar motorn vyn som 1280 × 1280 eftersom det inte finns något fönster,
så bildgränsen ovan är mätt i sidled, där bilden är sann.)

Fiender bakom en vägg bromsar inte heller — en inbromsning är spelets sätt att säga "här
finns en träff", och den får inte ljuga.

**Ett flackt hopp rakt in i sidan** mätte 700 px/s i sidled mot en blå: han nådde den i
samma bildruta som han nuddade marken, och innan `ATTACK_GRACE` fanns hann läget hinna
bli RULLAR före träffen — fienden överlevde och det kostade ett hjärta. Samma försök nu:
fienden dör, hjärtan 3 → 3, kedja 1. Det är samma rotorsak som väggarna och kanterna:
ett beslut om en krock får inte läsas ur ett tillstånd som rörelsen i samma bildruta
redan hunnit ändra.

## Kliva över småhinder

En krossad låda lämnar fyra bitar på 23 × 20 px och en dödad fiende fyra på 17 × 17 px.
Motorn kallar allt brantare än golvvinkeln för vägg, så innan det här vände RB vid varje
skärva: en lyckad strid lade en mur framför honom. Nu lyfter benen honom upp på det som
är lågt nog.

Klivet görs i tre frågor, i tur och ordning, och var och en kan säga nej:

1. **Hur högt är det?** En stråle uppifrån, 4 px innanför hindrets framkant, letar dess
   ovansida. Är hindret högre än steghöjden startar strålen *inuti* det och rapporterar
   ingenting — motorn ger ingen träff för en stråle som börjar i en kropp, vilket är
   precis rätt svar: det är en vägg och inte en sten.
2. **Får kroppen plats där uppe?** Provförflyttning rakt upp, höjden plus 3 px.
3. **Kommer han fram därifrån?** Provförflyttning framåt från den lyfta ställningen.

Mätt på fristående hinder, RB i full gångfart rakt in i dem:

| hinder | gående | rullande i 400 px/s |
| --- | --- | --- |
| 17 px (bit efter en fiende) | kliver över | kliver över |
| 20 px (bit efter en låda) | kliver över | — |
| 22 px | — | kliver över |
| 26 px (grundvärdet) | kliver över | kliver över |
| 28 px | vänder | — |
| 40 px (en hel låda) | vänder | — |
| 63 px (en avsats) | vänder | — |

Och på riktigt skräp, med fysik och allt:

| framför honom | steghöjd 0 | steghöjd 26 |
| --- | --- | --- |
| fyra bitar efter en fiende | vänder | tar sig förbi |
| fyra bitar efter en krossad låda | vänder | tar sig förbi |
| en hel låda | vänder | knuffar den framför sig |
| två lådor på varandra | vänder | vänder |

**Som boll kostar klivet fart, och då finns en till gräns.** Ett hjul tar en
trottoarkant som är lägre än dess radie, och bara om rörelseenergin räcker:
v² = v0² − 2·g·h. Utan den grenen vände en rullande RB mot varje skärva och studsade
bakåt — mätt bar en boll i 258 px/s ner för en 17 px hög bit rakt in i nästa och kom
tillbaka i **111 px/s åt andra hållet**, fast farten räckte till 24 px klättring. Nu
rullar han över och betalar: 258 px/s in, 138 px/s ut. Gränsen är alltså bollens radie
(22 px) för den som rullar och steghöjden (26 px) för den som går. Benen har ingen
energigräns alls — det är därför de finns.

**Klivet tas över flera bildrutor, inte på en.** Första versionen flyttade honom hela
vägen på en enda bildruta, och så såg det också ut: **36 px på en sextiondels sekund är
2200 px/s**, alltså sjutton gånger gångfarten — mätt i Lekplatsens småstenar, som är
24 × 22 px och alltså precis i klivbar höjd. Ett ben lyfter en kropp, det kastar den
inte. Nu tas klivet i takten `step_pace` (grund 250 px/s, ungefär ett vanligt steg i
tid), och uppåt först: en diagonal skrapar mot hindrets överkant, vilket är samma skäl
som provförflyttningarna görs i två steg. Mitt i ett kliv *är* klivet hans rörelse —
läggs den vanliga gången ovanpå flyttas han både klivet och ett steg till på samma
bildruta. Efter allt det är den största förflyttningen på en bildruta **4,6 px (280
px/s)** i samma mätning.

**Klivet måste bära honom förbi hindrets framkant, inte bara upp på den.** Första
versionen lyfte honom rakt upp och 10 px fram, och då blev han stående med tyngdpunkten
utanför kanten. En kant ger en lutande normal — mätt blev underlaget 25° brant — och
kantskyddets stråle svänger med underlaget, så den sköt ut i luften och han vände på
stället. Nu räknas steglängden ur var kontakten satt: fram till hindrets framkant plus
6 px.

**Kan benen lyfta honom upp, måste de också klara att ta honom ner.** Kantskyddet känner
efter mark 34 px framåt och 22 px ner, och stod han på något 23 px högt låg marken
framför *utanför* den strålen — han klev upp och blev stående och vände om och om igen
(mätt: han fastnade på 23 och 26 px). Kantskyddet har därför fått en andra fråga: hittas
**plan** mark inom steghöjden räknas den som mark. Gränsen för *backar* står kvar exakt
där den stod — en lutning framför honom ger en normal som avviker för mycket från den han
står på (kravet är 0,8 i skalärprodukt, alltså högst 36°), och då är det fortfarande en
backe han inte ska gå ner för (DECISIONS 28).

## Han vänder inte för att något nuddar honom

Förut vände RB i samma bildruta som benen rörde vid vad som helst. Det var en reflex och
inte ett beslut: en skärva, en låda han kunde ha knuffat och ett berg såg likadana ut.
Nu går han emot det en stund först, och under tiden kan tre saker hända — alla tre bättre
än att vända: han kliver upp på det, han knuffar undan det, eller han kommer ingenstans
och vänder till slut.

| | vänder efter |
| --- | --- |
| tålamod 0 (som förut) | 0,02 s |
| tålamod 0,35 s (grund) | 0,35 s |

Tålamodet nollställs så fort han kommer framåt, så något han kan knuffa vänder honom
aldrig. Att han *kan* knuffa en hel låda är i sig en rättelse: **knuffen räknades på
farten efter kollisionen**, och motorns glidning har redan skurit bort komponenten in i
lådan när den läses — en knuff rakt framifrån blev alltså nästan noll. Det är samma
rotorsak som landningen, väggarna och anfallsfönstret (DECISIONS 18, 23). Med farten från
*före* kollisionen flyttar han en hel låda 46 × 40 px framför sig i stället för att vända
vid den, medan två lådor på varandra fortfarande stoppar honom.

**Samma fel satt kvar i luften.** Ett hopp rakt in i en lådas sida flyttade den inte alls,
vid något läge på reglaget — och det är det renaste fallet av samma sak: farten in i lådan
skars till noll av krocken (mätt 500 px/s in, 2,5 px/s kvar) och reglaget multiplicerade
alltså med ingenting. Lådan flyttad, 500 px/s i sidled rakt in i sidan:

| knuffkraft | farten läst efter krocken | farten läst före |
| --- | --- | --- |
| 0,10 | 0,0 px | 0,7 px |
| 0,55 (grund) | 0,0 px | 45,7 px |
| 1,00 | 0,0 px | 104,6 px |
| 2,00 | 0,0 px | 354,2 px |

Ett hopp som *landar* intill lådan i samma ögonblick kändes däremot rätt hela tiden
(27,6 px vid grundvärdet), och skälet är lärorikt: där skar marken bort den *lodräta*
farten medan den framåtriktade överlevde, så knuffen hade en riktning kvar att räkna på.
Felet syntes alltså bara i det rena fallet — vilket är precis varför det stod kvar.

Klivet är benens arbete och kostar ingen fart. Det är inte generositet utan geometri: i
gångfart räcker rörelseenergin bara till 6 px av egen kraft (v²/2g med 130 px/s och
1400 px/s²), så en boll kan inte rulla över ens den minsta skärvan. Det *måste* vara en
förmåga hos benen, och därför gäller det bara när han går — rullande studsar han fortfarande
mot det han kör in i, och knuffar det framför sig.

## Lekplatsens andra trappa

Trappan efter kvartspipan gick inte att ta sig upp för med ett vanligt hopp: stegen låg
200 och 300 px över marken och hoppet når 169 px. Den är omgjord och uppmätt med samma
verktyg och samma krav som Klättringen — minst tre av nio siktvinklar ska landa rätt.

| hopp | vinklar som landar rätt |
| --- | --- |
| marken → steg 1 (100 px upp) | 60°–80° (3 av 9) |
| steg 1 → steg 2 (200 px upp) | 50°–80° (4 av 9) |

Tre mått kom ur mätningen och inte ur ritandet:

* **Ett steg behöver ungefär 130 px fri mark framför sig.** Första försöket lade steget
  90 px från kvartspipans lodräta kant, och där stannade RB 33 px från det: varje vinkel
  nådde bara underkanten, noll av nio. Med 140 px framför blev det tre.
* **Det nedersta steget måste vara tunnare än de andra.** Med 26 px tjocklek och ovansidan
  100 px upp blir det 74 px kvar under det, och RB är 70 px hög — han skrapar. 20 px
  tjocklek ger 80.
* **Lådstapeln får inte stå i nedslagsytan.** Med stapeln mitt på översta steget landade
  två av vinklarna på lådorna i stället för på steget (mätt 251 och 257 px över marken i
  stället för 200). Flyttad till bortre änden blev samma två vinklar träffar.

Bron på pelare fick samtidigt flytta. Den stod på marken under trappan, och pelarna går
från marken upp till 92 px — alltså rakt igenom ett steg som ligger 100 px upp. Den står
nu under den *första* trappan i stället, vars steg hänger 310 px upp och lämnar marken fri.

## Klättringen: farledens siktfönster

Banan är byggd efter en konceptskiss och sedan **mätt**: ett verktyg (`_route.tscn`)
ställer RB på varje avstamp, sveper siktet genom alla vinklar och räknar hur många som
faktiskt landar där de ska. Nio vinklar per hopp (var tionde grad). Två saker om
mätningen, för de påverkar siffrorna:

* **Avstampet ligger ungefär två kroppslängder från kanten.** Var han står när man
  trycker spelar roll — vid kanten når hoppet längre — och han går fram och tillbaka på
  avsatsen, så spelaren kan välja. Mätningen tar ett normalt läge, inte det bästa.
* **Alla svinghopp är mätta ur ett dött häng**, alltså utan någon sväng alls. Det är det
  svåraste fallet; med fart i pendeln blir fönstren större.
* **Ett svingben måste köras ensamt.** Körs flera i följd hakar RB fast i samma grepp han
  just lämnat, och benet rapporterar noll träffar fast det är helt i sin ordning. Tabellen
  nedan är mätt ben för ben; en körning i slingor gav tre avvikelser som alla försvann vid
  omkörning ensamma.

Tabellen mättes om efter att benen fått kliva över småhinder, och igen efter att klivet
gjorts mjukt och vändningen fått tålamod (se ovan). Alla nitton raderna kom tillbaka
oförändrade båda gångerna.

| Hopp | vinklar som landar rätt |
| --- | --- |
| start → steg 1 | 20°–80° (7 av 9) |
| steg 1 → steg 2 | 20°–70° (6) |
| steg 2 → steg 3 | 20°–70° (6) |
| steg 3 → avsats 1 | 50°–80° (4) |
| avsats 1 → avsats 2 | 50°–70° (3) |
| avsats 2 → blocket | 40°–70° (4) |
| blocket → stång 3 | 100°–140° (5) |
| stång 3 → stång 2 | 120°–140° (3) |
| stång 2 → lian 2 | 120°–150° (4) |
| lian 2 → lian 1 | 110°–170° (7) |
| lian 1 → stång 1 | 110°–170° (6) |
| stång 1 → balkongen | 110°–160° (6) |
| balkongen → stången i pelaren | 90°–120° (4) |
| stången → pelartoppen | 100°–120° (3) |
| pelartoppen → avsats A | 50°–80° (4) |
| A → B | 50°–80° (4) |
| B → C | 50°–80° (4) |
| C → D | 50°–80° (4) |
| D → platån | 50°–80° (4) |
| **platåns krön → flaggan** (hela rampen, utan fler tryck) | **20°–60° (5 av 5)**, se reservationen nedan |

Sista raden är hela finalen mätt i ett stycke: ett tryck på platåns krön, och sedan
ingenting alls. Han landar rullande på rampens avsats, rullar över krönet, faller genom
nedslagsbacken, svänger runt i skålen och kastas ut ur uppstudsen — 3,3 till 4,4
sekunder från tryck till flagga, och **varje vinkel mellan 20° och 60° tar honom hela
vägen**. Det är den mest förlåtande delen av banan, vilket är precis rätt för det som är
själva belöningen.

**Med reservation för att den siffran inte går att reproducera.** Finalen mäts numera av
verktyget självt (`_route.tscn`, sista benet), med avstampet på 2800 och ett enda tryck.
Den mätningen ger **2–4 vinklar av 5 och varierar mellan körningar med samma
inställningar** — 20° och 40° går fram varje gång, 30° aldrig, och 50° och 60° vänder
utfall från körning till körning. Sekvensen är lång och studsig, och verktyget trycker på
klockslag och inte på känsla, så små skillnader i när trycket faller växer genom backen,
skålen och uppstudsen. Siffran 5 av 5 mättes med ett annat avstamp och går alltså inte
att jämföra rakt av. Det som *är* jämförbart, och det enda som den här mätningen duger
till: samma spridning kommer med och utan att benen kliver över småhinder (tre körningar
var: 3, 3, 3 mot 4, 3, 2), så den förmågan rör inte finalen.

Tre hopp i ett tidigt utkast mätte noll eller en vinkel av nio, och alla tre av samma
skäl: höjdskillnaden låg för nära hoppets tak. Räckvidden faller brant när hoppet ska
stiga — 346 px rakt fram, men bara omkring 230 px om det samtidigt ska upp 100 px, och
inget alls över 169 px. Tumregeln banan är byggd efter: **stiger hoppet 100 px får gapet
vara högst 180 px, stiger det 50 px högst 240 px.**

En detalj värd att skriva ner: vad som räknas är kroppens *mitt*, inte fötterna. Att
landa på en avsats kräver 35 px mer stigning än avståndet till kanten antyder. Och ett
grepp som ligger *nedanför* honom är svårare än ett som ligger i höjd med honom: en
stång 70 px ner mätte 2 vinklar av 9, samma stång i hans egen höjd 6.

## Rampen: att bygga fart som ett hopp inte kan ge

Flaggan står 120 px under rampens avsats men 2200 px från den, och 660 px över marken
under sig. Den går alltså inte att hoppa till från någonstans — hoppet når 346 px långt
eller 169 px högt, dubbelhoppet 338 px rakt upp. Enda vägen dit är rampen, och det är
hela poängen: **hoppkraften läggs till den fart han redan har, så står han still på
marken finns ingen uppåtfart att lägga den till.** En ramp kan däremot peka farten uppåt.

Fem saker mättes fram, och alla gäller varje ramp vi bygger härefter:

| | |
| --- | --- |
| Krönets radie | minst **v²/1550** px, annars lättar han. Vid 800 px/s alltså 413 px; rampens krön har 700 |
| Bågens punkttäthet | krönet mäts som hur mycket lutningen ändrar sig **per bildruta**. Med glesa punkter kommer hela ändringen på en gång, och en mjuk kurva läses som ett tvärt hörn: mätt lyfte han från en 400-radie i 665 px/s, där gränsen ligger vid 190 |
| Brant backe | går **inte** att hålla sig kvar i. För att följa en kurva ända ner till 60° i 790 px/s krävs en radie på över 4000 px. Alltså ska han lämna krönet och flyga — och backen nedanför ska ha formen av hans egen kastbana, så att nedslaget blir tangentiellt och nästan ingen fart går förlorad |
| Uppstudsens vinkel | 62° kastar honom nästan rakt upp — hög båge, men han landar där han startade. **45°** ger halva farten uppåt och halva framåt |
| Läppens höjd | avgör om bågen blir **hög eller lång**. Varje 100 px läppen ligger under avsatsen ger 22 px lägre topp men mer fart, alltså längre flykt. Rampens läpp ligger 200 px under avsatsen, och det räckte för att fördubbla utfarten |

Mätt genom rampen med 788 px/s in på avsatsen: **1019 px/s kvar vid läppen** (mot 650
med den flacka backen och läppen i avsatsens höjd), och bågen toppar 223 px över läppen.
Den flyger 2200 px till flaggplatån.

Och en sak till, som inte är fysik utan geometri: **rampens ändkanter måste vara
lodräta.** En vinkelrät kant på en 45-graders läpp lämnar en liten hylla utanför rampen,
och mätt blev RB stående på den i stället för att falla ner — en osynlig hylla är en
återvändsgränd som ingen kan förstå.

## Backar som går att ta sig ner för

Två regler föll ut av banbygget, och båda gäller alla banor vi bygger härefter.

**Han går aldrig ner för något brantare än ungefär 33°.** Kantskyddet känner efter mark
34 px framåt och 22 px ner; lutar underlaget mer än så finns ingen mark att känna, och
då vänder han — precis som vid en avgrund. Det betyder att en backe brantare än 33°
bara går att komma ner för genom att *hoppa* ner i den. Kantskyddet går att stänga av i
panelen, men en bana får inte kräva det.

**Bygg aldrig en gångbar backe mellan 33° och 43° av många korta segment.** Där går han
på benen, alltså som en kapsel, och en kapsel kan haka fast i hörnen mellan segmenten:
mätt blev han stående på en 40,8-graders bit av platåns backe med full gångfart och kom
ingenstans, bildruta efter bildruta. Som boll är han en cirkel och rullar över samma
hörn utan att märka dem. Platåns backe börjar därför på 48° direkt vid krönet — då är
han boll från första ögonblicket — och planar ut nedtill, så att farten pekar vågrätt
när han lämnar avsatsen.

## Tak och tunnlar

Uppmätt genom att skicka in honom i en tunnel med sänkt tak:

| Takhöjd | Boll | Gående |
| --- | --- | --- |
| 44 px | stoppad | stoppad |
| 46 px | **igenom** | stoppad |
| 70 px | igenom | stoppad |
| 72 px | igenom | **igenom** |

Bollen behöver alltså 46 px, den gående RB 72 — två pixlars luft utöver kroppen
i båda fallen.

## Verkstadens mekaniker

Uppmätt i banan, med grundvärdena:

| | mätt |
| --- | --- |
| Studsmatta, studstal 1,0 | 300 px fall ger 290, 290, 286 px tillbaka |
| Studsmatta utan bukt | RB vandrar av duken efter tre studsar (700 → 878 px) |
| Studsmatta med bukt 0,25 | håller sig kvar på duken, pendlar 626–768 px |
| Stång, radie 60 px | behåller 100 % av farten in i greppet, oavsett infallsvinkel |
| Lian, L = 330 px | 100 % rakt genom botten av svängen, 79 % (63 % av energin) snett in |
| Lian, hakad 120 px ner | svängningstid 2,3 s |
| Lian, hakad 240 px ner | svängningstid 2,9 s |
| Kroppen under haken | 60 px, lika i stång och lian |
| Benens eftergift, ω = 2 / 4 rad/s | 4,1 / 8,4 px längre radie |
| Fånga en stång med hopp rakt upp | lyckas från tre startpunkter under den, greppet efter 8–14 bildrutor |
| Gå ut på en matta | 110 bildrutor av 260 på duken — förut vände han vid dess kant och nådde den aldrig |
| Falla 300 px ner på en matta | tillbaka till samma höjd |

Svängningstiden är 2π√(L/g) och kommer alltså ur längden, inte ur en inställning:
ändrar man tempot i panelen ändras pendlarna lika mycket som hoppet. På en lian är
det *var man tar tag* som sätter längden — högt upp ger en kort och snabb pendel,
långt ner en lång och långsam. Kroppen hänger en kroppslängd nedanför haken i
båda fallen: han hänger i benen, inte med kroppen mitt i repet.

Benen ger dessutom efter för centrifugalkraften: uttänjningen följer ω²r/g, och när
radien ändras bevaras rörelsemängdsmomentet r²ω, precis som när en konståkare drar
in armarna. Sträcker han ut sig går varvet långsammare, av sig självt.

## Rutnät (förslag, inte beslutat)

**48 px ruta.** Valet följer av tunnelmätningen: en ruta hög öppning (48) släpper
igenom bollen men inte den gående, två rutor (96) släpper igenom båda. Det ger
den enklaste möjliga regeln för banbygge, och den regeln är samma sak som spelets
första förmåga — låga gångar kräver att han rullar.

Med 48 px ruta blir de mätta måtten:

| | rutor |
| --- | --- |
| RB stående | 1,5 hög × 0,9 bred |
| Bollen | 0,9 |
| Hopp rakt upp | 3,5 |
| Längsta hopp | 7,2 |

Att bygga på: **3 rutor upp och 7 rutor i sidled** går alltid, med marginal.

Lutningar som rutnätet ger av sig självt:

| Ruttrappa | Grader | Vad RB gör |
| --- | --- | --- |
| 1:3 | 18,4° | går uppför lätt |
| 1:2 | 26,6° | går uppför |
| 1:1 | 45° | rullar — benen åker in |
| 2:1 | 63,4° | vägg, han tar sig inte upp |

Det är en ovanligt ren uppdelning: rutnätets tre naturliga lutningar landar en
i varje kategori, och 43° hamnar mitt i glappet mellan 26,6 och 45, alltså
långt från båda. Gränsen kan flyttas några grader åt endera hållet utan att en
enda byggd backe byter beteende.
