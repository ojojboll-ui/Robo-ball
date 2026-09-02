# Robo Ball — speldesign

## 1. Designprinciper

Fem regler som alla andra beslut ska kunna härledas ur:

1. **En signal räcker.** Spelet får aldrig kräva två samtidiga inmatningar, håll,
   dubbelklick eller riktning. "Signal" = valfri knapp, klick, tryck, blink, blås
   eller blickfixering. Allt annat är krydda.
2. **Ingen tidspress som spelaren inte kan ställa in.** Varje timingfönster, pilens
   hastighet, slow motion-faktorn och fiendernas tempo ska gå att skruva på.
3. **Att inte trycka är ett giltigt drag.** RB går själv. En spelare som behöver 40
   sekunder på sig att fatta beslut ska inte straffas för det — världen väntar
   (bokstavligen, se "vilolägen" nedan).
4. **Aldrig återvändsgränd.** Spelaren ska inte kunna hamna i ett läge som kräver
   omstart. Om RB fastnar finns alltid en väg ut, eller så återställs han automatiskt.
5. **Menyerna är en del av spelet.** Om huvudmenyn kräver en mus är spelet
   ospelbart, hur bra själva spelet än är. Se ACCESSIBILITY.md, avsnitt "Scanning-UI".

## 2. Kärnloop

```
        ┌──────────────────────────────────────────────┐
        │                                              │
   ┌────▼─────┐   signal    ┌──────────┐   signal   ┌──┴───────┐
   │  GÅENDE  ├────────────►│  SIKTAR  ├───────────►│  I LUFTEN │
   │ auto-gång│             │ slow-mo  │            │ ballistisk│
   │ vänd vid │◄────────────┤ pendelpil│            │  bana     │
   │  vägg    │  timeout /  └──────────┘            └──┬───────┘
   └────▲─────┘  avbryt                                │ landning
        │                                              │
        └──────────────────────────────────────────────┘
```

### GÅENDE
RB rullar/går i konstant fart. Träffar han en vägg, ett hinder eller kanten av en
plattform vänder han och går åt andra hållet. Han faller inte ner för kanter av misstag
i grundläget (**kantskydd**, avstängningsbart) — annars blir auto-gång ett straff.

### SIKTAR
Vid signal sätter RB sig på huk (bild 2 i konceptskisserna). En pil dyker upp ovanför
honom och pendlar fram och tillbaka över ett vinkelspann. Världen går i slow motion —
fiender, projektiler och rörliga plattformar saktas ner, men pilen och UI:t gör det inte.
Slow motion är alltså inte en effekt, det är **speltid ÷ beslutstid**, och därmed en
tillgänglighetsparameter.

* Pilen pendlar mellan två vinklar (grund: 20°–160°, dvs. aldrig rakt ner).
* Pilens längd visar hoppkraft — som standard fast, men se "Två-stegssikte" nedan.
* En prickad förhandsbana visar var RB landar (av/på). Eftersom lufttiden är helt
  ballistisk är banan exakt förutsägbar, inte en gissning.
* Efter N sekunder utan andra signalen: timeout tillbaka till GÅENDE (justerbart,
  kan sättas till "aldrig").

### I LUFTEN
RB kastas iväg längs pilen och följer en ballistisk bana. Han är nu ett projektil-objekt:
träffar han sköra föremål krossas de med impuls proportionell mot rörelseenergin
(Angry Birds-modellen). Träffar han en vägg studsar han eller glider ner, beroende på
vinkel och vilka förmågor han har.

Vid landning återgår han till GÅENDE i den riktning han rörde sig.

### Vilolägen
Om spelaren inte gör något på lång tid ska RB inte gå ihjäl sig. Två mekanismer:

* **Fickor:** nivådesignen bygger på att auto-gång alltid leder tillbaka till en säker
  slinga (en platå, en dal, en cirkulär bana) i stället för rakt ner i en avgrund.
* **Autopaus:** efter X sekunder utan signal stannar RB och tittar sig omkring. Nästa
  signal väcker honom. (Av som standard, på i "lugnt läge".)

## 3. Styrningsvarianter

Alla varianter ger samma spel — de skiljer sig bara i hur de två signalerna avges.
Väljs i en profil, inte i en undermeny någonstans.

| Variant | Signal 1 | Signal 2 | Passar |
|---|---|---|---|
| **Klassisk** (grund) | tryck | tryck | de flesta |
| **Håll & släpp** | tryck ner | släpp | den som lättare håller än trycker exakt |
| **Auto-sikte** | tryck | *ingen* — spelet hoppar automatiskt i bästa vinkel | mycket grav motorik, eller yngre barn |
| **Två-knapp** | knapp A | knapp B | den som har två kontakter och tycker det är enklare |
| **Scanning** | pilen stannar på diskreta vinklar i steg | tryck väljer aktuell | kognitivt lättare, långsammare |

**Auto-sikte** är viktig: den gör spelet spelbart för någon som bara kan avge en signal
per gång med lång latens. Spelet väljer då den vinkel som leder till framsteg. Det är
inte "fusk" — det är att flytta svårighetsgraden från precision till timing.

## 4. Fysikkänsla

Tre olika fysikbeteenden som måste samexistera (se TECH.md för implementation):

1. **RB på mark** — Sonic-modellen. Han följer underlagets normal, kan åka ner för ramper,
   samla fart i sluttningar och (med rätt fart) klara loopar och korkskruvar. Det här är
   *inte* generell stelkroppsfysik utan en handskriven markkontroller, annars blir det
   klumpigt.
2. **RB i luften** — ren ballistik. Förutsägbar, siktbar, ingen luftstyrning (det finns
   ingen input att styra med).
3. **Världen** — riktig stelkroppsfysik. Lådor, stenar, spröda plankor, gungande
   trapetser, vippbrädor. Det är här Angry Birds-känslan bor: RB slår in i en stapel
   och den rasar på ett sätt som ingen har animerat i förväg.

Sammanstötning mellan (1/2) och (3): RB applicerar impuls på stelkroppar; stelkroppar
knuffar bara RB om han är i luften. På mark ignorerar RB små knuffar — annars går
markkontrollern sönder.

## 5. Förmågor (metroidvania-grindarna)

Varje förmåga ska (a) förändra hur RB rör sig, (b) öppna en typ av grind som funnits
synlig tidigare, och (c) gå att förstå utan text.

| # | Förmåga | Rörelse | Öppnar |
|---|---|---|---|
| 1 | **Rulla** (start) | korta, låga hopp | — |
| 2 | **Strutsbenen** | högre och längre hopp, kliver över småkanter | höga avsatser, breda hål |
| 3 | **Spikar** | fastnar på och rullar uppför vertikala väggar och i tak | schakt, upp-och-nedvända rum |
| 4 | **Hårt skal** | krossar spröda block, tål fall och smällar | murar, rasområden, taggar |
| 5 | **Dubbelhoppet** | ett andra hopp mitt i luften, med samma två tryck | långa gap, höga avsatser, omtag när första hoppet blev fel |
| 6 | **Ficklampan** | ljuskägla ur ögat, lyser upp mörker | mörka grottor, ljuskänsliga fiender/mekanismer |
| 7 | **Kroken** *(förslag)* | fäster i trapetser och rälsar, svingar (skiss 4) | långa gap, hängande sektioner |
| 8 | **Gummiskal** *(förslag)* | studsar i stället för att stanna, kedjehopp | höga schakt, studsbanepussel |
| 9 | **Turbon** *(förslag)* | högre grundfart → loopar och korkskruvar går att klara | Sonic-sektionerna, rampbanor |

**I v1 (ca 90 minuter) ingår 1, 2, 3 och 5:** rulla, strutsbenen, spikar och dubbelhoppet.
De täcker horisontell, vertikal och "utanför golvet"-rörelse plus räckvidd, och gör
kartan tre gånger större utan att lägga till en enda knapp.

Dubbelhoppet är värt en anmärkning, eftersom det är just den sortens förmåga som brukar
kräva en extra knapp i andra spel. Här gör den inte det: i luften betyder ett tryck
samma sak som på marken — RB stannar upp, pilen svepar, nästa tryck kastar iväg honom
igen. Förmågan lägger alltså till räckvidd utan att lägga till inmatning, precis som
regeln nedan kräver. Den ger dessutom något värdefullare än räckvidd: ett omtag. Ett
hopp som blev fel går att rädda i luften, och för en spelare vars timing är ojämn är
det skillnaden mellan att misslyckas och att få försöka igen. Hårt skal, kroken,
gummiskalet, turbon och ficklampan flyttas till v2 — notera att den förstörbara fysiken
finns i spelet ändå från start, eftersom saker går sönder av rörelseenergi; det hårda
skalet höjer bara tröskeln, det skapar den inte.

**Regel:** ingen förmåga får göra styrningen svårare. En förmåga som kräver att man
trycker "i rätt ögonblick under hoppet" bryter mot premissen. Förmågor ändrar
*egenskaper* (räckvidd, vidhäftning, hårdhet, sikt), inte *inmatning*.

## 6. Värld och progression

* **Struktur:** sammanhängande 2D-karta i Metroid-anda, uppdelad i 5–6 biotoper som
  möts i en central hubb (kraschplatsen). Tornet i mitten är synligt från nästan
  överallt och blir slutmålet.
* **Biotoper i v1:** kraschplatsen (tutorial, benen), rörsystemet (spikar, vertikalt),
  skrotupplaget (förstörbar fysik), klyftorna (dubbelhoppet), och en kort tornsektion som
  avslutning. Grottorna följer med ficklampan till v2, liksom rampdalen och det fulla
  tornet.
* **Backtracking:** ska alltid vara kortare än första resan — genvägar som låses upp
  inifrån, och snabbresa mellan hittade laddstationer.
* **Sparning:** kontinuerlig autosparning, inte sparrum. Spelet ska kunna stängas av
  mitt i ett hopp och återupptas exakt där.
* **Fiender:** rör sig i förutsägbara mönster, telegraferar allt de gör, och kan alltid
  undvikas — aldrig krävas att man dödar dem för att komma vidare (svårighetsgrad ska
  inte kräva precision).
* **Skada:** grundläget är "knuffas tillbaka och tappa lite fart", inte "dör och startar
  om". Livssystemet ska gå att ställa på odödlig utan att låsa något innehåll.

## 7. Berättelse

RB kraschlandar på en planet där robotarna har blivit elaka. Han saknar delar efter
kraschen — därför börjar han som en boll utan ben. Delarna finns utspridda över
planeten, och det stora tornet i mitten är källan till det som gått fel.

Berättas utan text: mellansekvenser i samma handteckningsstil som konceptskisserna,
tysta, korta, och alltid avbrytbara med signal. Ingen dialog som kräver läsning
(många i målgruppen läser inte), men allt röstas eller stöds av ljud och bild.

## 8. Grafisk riktning

Konceptskisserna sätter tonen: handteckning, tuschlinje, kritig skuggning, starka
neonrosa/blå accenter mot dova bakgrunder. Det är en stil som (a) ser dyr ut utan att
kräva pixelperfekt animation, (b) läser bra även med nedsatt syn om kontrasten hålls
hög, och (c) skalar till vektorgrafik utan att bli steril.

Krav från tillgänglighetssidan: RB och alla farliga föremål måste läsa som silhuetter
även i gråskala och även för den med nedsatt syn. Bakgrunder får aldrig ha samma
kontrastnivå som spelbara ytor. Se ACCESSIBILITY.md.
