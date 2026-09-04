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
| Trapets, L = 200 px | svängningstid 2,4 s |
| Lian, L = 330 px | svängningstid 3,1 s |
| Grepp | bevarar farten längs banan; i ett brant infall blev 971 px/s till 541 (56 %) |

Svängningstiden är 2π√(L/g) och kommer alltså ur längden, inte ur en inställning:
ändrar man tempot i panelen ändras pendlarna lika mycket som hoppet.

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
