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
| Laserns räckvidd | 1400 px, stoppas av väggar |
| Osårbar efter en träff | 1,2 s |

Kontrollerat i banan: ett fall på en blå dödar den och ger kedja 1 med 520 px/s uppåt;
att gå in i samma sorts fiende på marken kostar ett hjärta och fienden överlever; en
laser med fri sikt dödar en flygande röd och ger också kedja 1; och en röd bakom en
avsats skyddas av avsatsen — strålen tar stopp i väggen.

**Ett flackt hopp rakt in i sidan** mätte 700 px/s i sidled mot en blå: han nådde den i
samma bildruta som han nuddade marken, och innan `ATTACK_GRACE` fanns hann läget hinna
bli RULLAR före träffen — fienden överlevde och det kostade ett hjärta. Samma försök nu:
fienden dör, hjärtan 3 → 3, kedja 1. Det är samma rotorsak som väggarna och kanterna:
ett beslut om en krock får inte läsas ur ett tillstånd som rörelsen i samma bildruta
redan hunnit ändra.

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

| Hopp | vinklar som landar rätt |
| --- | --- |
| start → steg 1 | 20°–80° (6 av 9) |
| steg 1 → steg 2 | 20°–80° (7) |
| steg 2 → steg 3 | 20°–80° (7) |
| steg 3 → avsats 1 | 50°–80° (4) |
| avsats 1 → avsats 2 | 50°–70° (3) |
| avsats 2 → blocket | 50°–70° (3) |
| blocket → stång 2 | 100°–150° (6) |
| stång 2 → stång 1 | 120°–140° (3) |
| stång 1 → lian 2 | 120°–150° (4) |
| lian 2 → lian 1 | 110°–160° (6) |
| lian 1 → balkongen | 120°–140° (3) |
| balkongen → stången i pelaren | 90°–120° (4) |
| stången → pelartoppen | 100°–120° (3) |
| pelartoppen → avsats A | 50°–80° (4) |
| A → B | 50°–80° (4) |
| B → C | 50°–80° (4) |
| C → platån | 50°–80° (4) |
| **platåns krön → flaggan** (hela rampen, utan fler tryck) | **20°–40° (3 av 6)** |

Sista raden är hela finalen mätt i ett stycke: ett tryck på platåns krön, och sedan
ingenting alls. Han landar rullande på avsatsen, rullar över krönet ner i skålen, upp
för uppstudsen och flyger till flaggan — 3,3 till 3,7 sekunder från tryck till flagga.
Med ett flackare hopp (20°) kommer han in i skålen i 788 px/s, med ett brantare (40°) i
673. Under ungefär 650 px/s tar farten slut i uppstudsen och han rullar tillbaka ner —
ingen skada skedd, han hamnar på blocket eller på avsatsen igen och kan försöka om.

Tre hopp i första utkastet mätte noll eller en vinkel av nio, och alla tre av samma
skäl: höjdskillnaden låg för nära hoppets tak. Räckvidden faller brant när hoppet ska
stiga — 346 px rakt fram, men bara omkring 230 px om det samtidigt ska upp 100 px, och
inget alls över 169 px. Tumregeln banan är byggd efter: **stiger hoppet 100 px får gapet
vara högst 180 px, stiger det 50 px högst 240 px.**

En detalj värd att skriva ner: vad som räknas är kroppens *mitt*, inte fötterna. Att
landa på en avsats kräver 35 px mer stigning än avståndet till kanten antyder.

## Rampen: att bygga fart som ett hopp inte kan ge

Flaggan står 50 px över avsatsen och 1840 px från den, och 740 px över blocket. Den går
alltså inte att hoppa till från någonstans — hoppet når 346 px långt eller 169 px högt,
och dubbelhoppet 338 px rakt upp. Enda vägen dit är rampen, och det är hela poängen:
**hoppkraften läggs till den fart han redan har, så står han still på marken finns ingen
uppåtfart att lägga den till.** En ramp kan däremot peka farten uppåt.

Fyra saker mättes fram under bygget, och alla fyra gäller varje ramp vi bygger härefter:

| | |
| --- | --- |
| Krönets radie | minst **v²/1550** px, annars lättar han. Vid 800 px/s alltså 413 px; skålens krön har 700 |
| Bågens punkttäthet | krönet mäts som hur mycket lutningen ändrar sig **per bildruta**. Med glesa punkter kommer hela ändringen på en gång, och en mjuk kurva läses som ett tvärt hörn: mätt lyfte han från en 400-radie i 665 px/s, där gränsen ligger vid 190 |
| Uppstudsens vinkel | 62° kastar honom nästan rakt upp — hög båge, men han landar där han startade. **45°** ger halva farten uppåt och halva framåt, alltså en båge som når någonstans |
| Läppens höjd | varje 100 px läppen ligger **under** avsatsen sänker toppen av bågen 22 px. Skålens läpp ligger därför i exakt samma höjd som avsatsen, som i en riktig halfpipe |

Mätt genom skålen vid 788 px/s in: **1528 px/s i botten**, 650 px/s kvar vid läppen, och
bågen toppar 103 px över läppen, 152 px ut. Det låter lite, men det är tillräckligt:
tornet står 91 px bort och dess topp 50 px över läppen.

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
