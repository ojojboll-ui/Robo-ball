# Robo Ball

Ett 2D-metroidvania som går att spela hela vägen igenom med **en enda knapp**, i
webbläsaren, utan installation.

RB är en robotboll med ett öga och strutsben som kraschlandar på en planet full av elaka
robotar. Han går automatiskt och vänder vid väggar. Ett tryck får honom att sätta sig och
sikta — en pil pendlar över honom medan världen går i slow motion. Ett tryck till, och
han kastar sig iväg. Det är hela styrningen.

Målgruppen är barn och unga med motoriska funktionsnedsättningar som inte kan spela
vanliga TV-spel därför att kontrollerna kräver för många samtidiga inmatningar.
Tillgänglighet är inte en feature i det här projektet — det är premissen.

## Läget

**Fas 0 — gråboxprototypen körs.** RB går av sig själv och vänder vid väggar, ett tryck
sätter honom i siktläge med pendlande pil och förhandsbana medan världen går i slow
motion, ett tryck till kastar iväg honom, och lådstapeln rasar av rörelseenergi.
Verifierat i Godot 4.5 och som webbygge i webbläsare.

**Låsta beslut:** Godot 4 · GDScript · webben som förstahandsplattform · ca 90 minuters
speltid i första utgåvan · fyra förmågor (rulla, ben, spikar, dubbelhopp) · fysiken som
innehåll, inte ytbehandling. Se [docs/DECISIONS.md](docs/DECISIONS.md).

## Dokumentation

| Dokument | Innehåll |
|---|---|
| [docs/DESIGN.md](docs/DESIGN.md) | Speldesign: kärnloop, styrning, förmågor, värld, progression |
| [docs/TECH.md](docs/TECH.md) | Teknikval, arkitektur, fysikmodell, webbexportens fällor |
| [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md) | Tillgänglighetskrav, inställningsmatris, testprotokoll |
| [docs/PROJECTPLAN.md](docs/PROJECTPLAN.md) | Faser, milstolpar, tidsuppskattning, risker, finansiering |
| [docs/METRICS.md](docs/METRICS.md) | Uppmätta mått: backar, hopp, takhöjder, rutnät |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Beslutslogg |
| [concept/](concept/) | Konceptskisser |

## Köra spelet

Öppna `game/` i Godot 4.5 och tryck på play. Eller från terminalen:

```sh
godot --path game
```

Spelet styrs med **en enda signal**: vilken tangent som helst, klick var som helst,
skärmtryck var som helst, valfri knapp på en handkontroll. Ett tryck siktar, ett till
hoppar.

**Kugghjulet uppe till höger** öppnar inställningspanelen. Innehållet ligger i sex
flikar, eftersom ett trettiotal reglage i en enda lista blev längre än vad någon orkar
bläddra igenom mitt i ett speltest:

| Flik | Innehåll |
| --- | --- |
| Sikte | Pilens hastighet, slow motion, vinkelsteg, bågens gränser, hoppkraft, gravitation, tempoknapparna och extra hopp i luften |
| Rörelse | Gångfart och acceleration, markfäste, hur mycket fart som följer med i landningen och i hoppet, studs mot väggar, knuffkraft, benens fjädring |
| Rullning | När benen åker in (lutning, benens högsta takt och absolut fart) med uträknad klättergräns under, indragningstakt, förbli boll i luften, förberedd rullning i luften, rullmotstånd |
| Föremål | Lådornas fysik, effekter, studsmattornas studs och bukt, stängernas och lianernas grepp och dämpning, samt fiendernas fart, studsen på dem, skjutsiktet, laserns räckvidd, osårbarheten och antalet hjärtan |
| Hjälp | Styrningsvariant, förhandsbana, kantskydd, spelhastighet, dubbeltrycksfilter, timeout |
| Bana | Banval, börja om, snabbresa och återställning av alla inställningar |

Vilken flik som var öppen sparas tillsammans med inställningarna, så panelen öppnas där
man var förra gången. Allt slår igenom direkt, mitt i spelet. Panelen äter sina egna
tryck, så ett finger på ett reglage får aldrig RB att hoppa.

Panelen är ett verktyg för den som leder ett speltest — inte spelets meny. Den riktiga
menyn ska gå att använda med samma enda signal som spelet, och byggs i fas 1
(se docs/ACCESSIBILITY.md avsnitt 4).

F1 öppnar panelen, F2 växlar styrningsvariant, F8 börjar om. Funktionstangenter är
undantagna från spelets signal — inget hjälpmedel skickar dem, så undantaget kostar
ingen tillgänglighet.

## Banorna

Fem banor, valbara i panelen under *Bana* (eller med F3). De fyra första är verkstäder,
inte nivåer; den femte är den första riktiga banan, med ett mål. I alla är marken
sammanhängande hela vägen — RB går av sig själv, och en bana där auto-gången kan leda
ner i en avgrund straffar spelaren för att inte trycka.

**Lekplatsen.** Lös småsten direkt vid starten, två raka ramper, en hoppbacke och en
kvartspipa med böjda ytor, en plattformstrappa, och fem lådformationer — pyramid, tre
enkelbreda torn, mur, en bro på pelare och en stapel högst upp i trappan.

**Rullbanan.** Bara rullfysik. En vinkeltrappa med lutningar på 15, 25, 35, 41, 45 och 55
grader där man ser exakt var han slutar orka, var benen åker in och var fästet släpper; en skål där han
pendlar och rullmotståndet blir synligt; en puckelbana; och en avsats för en lång
utrullning som slutar i en lådstapel.

**Verkstaden.** Banan där nya mekaniker provas innan någon bestämmer sig för om de
ska vara med (docs/DECISIONS.md 20). Tre studsmattor infällda i marken — man går rakt
ut på dem, och de studsar när man landar på dem uppifrån. En trappa upp till en avsats
med en matta under, så att man kan gå av kanten och studsa tillbaka upp. Tre fasta grepp som
hänger fritt i luften, 185 px över marken: precis inom räckhåll för ett hopp rakt upp,
och utan pelare omkring sig som är i vägen. Och tre lianer, nästan tre gånger så långa som
stängerna och därför märkbart långsammare.

RB hakar fast av sig själv när han far förbi, och hänger då **i benen, upp och ner** —
samma ben, samma IK och samma ritning som när han går, bara med fötterna satta i
greppet och kroppens upp vänd åt andra hållet. Svängningen går i **riktig tid**, och ett
tryck betyder *sikta*: pendeln fryses, pilen sveper i slow motion, och nästa tryck
skickar iväg honom med svängens fart plus avstampet. Medan han hänger ritas **banan han
skulle få om han släppte nu**, som ändrar sig hela tiden medan han svänger — den
prickade kurvan *är* farten han har, ritad. Att inte trycka är alltid tillåtet: han
svänger kvar.

Skillnaden mellan de två greppen är hela poängen med att ha båda:

| | vad greppet gör med farten |
| --- | --- |
| **Stången** sitter fast och hakas med benen på den sida han passerar | behåller allt — en riktningsväxel, lika mycket fart ut som in |
| **Lianen** greppas var som helst längs repet — benen hakas där, kroppen hänger nedanför, precis som i stången | behåller farten längs banan: 100 % genom botten av svängen, 79 % snett in. Var man tar tag sätter pendelns längd: 2,3 s högt upp, 2,9 s långt ner |

**Fienderna.** Fyrkanter med elaka ögon. Två sorter, och skillnaden är hela poängen:

| | träffa den i ett hopp | röra den på marken | lasern |
| --- | --- | --- | --- |
| **Blå**, går på marken | den dör | RB tappar ett hjärta | den dör |
| **Röd**, flyger i en sinusvåg | händer inget | RB tappar ett hjärta | den dör |

Samma blå fiende är alltså farlig eller ofarlig beroende på vad RB själv gör — den
enklaste sortens regel ett barn kan läsa av på egen hand. Och det räcker att han är i
ett hopp: en flack båge rakt in i sidan räknas lika mycket som en landning uppifrån,
och även en träff strax efter landningen räknas, så att en hundradels sekund inte
avgör om samma rörelse blev en träff eller en skada.

Banan håller sorterna isär: blå i första halvan, röda i den andra, där luftrummet är
fritt från avsatser. Blandade lär de ut två saker samtidigt, och då lär de inte ut
någon.

**Kedjan.** Varje dödad fiende öppnar siktet igen i slow motion, så länge han inte
nuddat marken. Ett tryck räcker för att fortsätta från fiende till fiende, och den som
inte hinner tappar bara kedjan. Räknaren syns uppe till höger från två i rad.

**Lasern.** Är närmaste fiende röd blir siktet ett annat: en rak visare som går runt
hela varvet som en klocka, och nästa tryck skickar en stråle ur ögat. Strålen stoppas
av väggar, så en röd bakom en avsats måste man ta sig till.

**Hjärtan.** Tre stycken. Tar de slut börjar banan om från början med alla fiender
tillbaka — att förlora är att få börja om, inte att förlora något man byggt upp.

**Klättringen.** Den första banan med ett *mål* i stället för en verkstad, byggd efter
en konceptskiss. Tre farleder ovanpå varandra, och man går dem i sicksack:

1. **Nedersta, åt höger.** Tre trappsteg längs marken och två avsatser upp till det
   stora blocket. Bara hopp.
2. **Mellersta, åt vänster.** Tillbaka genom två stänger och två lianer, och sista
   svinget landar på balkongen vid vänsterpelaren. Bara grepp.
3. **Översta, åt höger.** Upp för avsatserna till platån, ner för dess backe — den är
   brantare än benen klarar, så han *rullar* och får fart — och så ett avstamp från
   avsatsen över gapet till flaggtornet.

Samma bana tre gånger i tre höjder, och varje varv byter mekanik: hoppa, svinga, rulla.
Flaggan står på tornet, och RB når den genom att gå in i den — inget sista precist
tryck, eftersom han går av sig själv. Då small det konfetti, och banan börjar om.

Varje hopp i farleden är uppmätt: hur många av siktets vinklar som faktiskt landar rätt
står i docs/METRICS.md. Och varje miss faller ner i en farled man kan ta sig vidare
från — marken bär hela banan, blocket ligger under gapet till tornet, balkongen under
stången. Ingen väg kan köra fast.

Snabbresa mellan stationerna finns i panelens *Bana*-flik och byggs om när banan byts.

## Bygga

CI bygger webb- och Windowsversionen vid varje push till `main` och lägger dem som
artefakter på körningen. Lokalt:

```sh
godot --headless --path game --export-release "Web" ../build/web/index.html
godot --headless --path game --export-release "Windows Desktop" ../build/windows/RoboBall.exe
```

Vill du ha en länk att öppna på telefonen: gör repot publikt, aktivera GitHub Pages
och sätt variabeln `ENABLE_PAGES` till `true` under *Settings → Secrets and variables →
Actions → Variables*. Då publiceras webbygget automatiskt.

## Struktur

```
game/
  core/     Settings, WorldClock, InputSignal, Palette
  actor/    RB — lägen, sikte, hoppsimulering, ritning
  world/    gråboxbanan och de destruerbara lådorna
  ui/       HUD och utvecklarpanel (scanning-menyn kommer i fas 1)
  main/     prototypens startscen
docs/       design, teknik, tillgänglighet, projektplan, beslut
concept/    konceptskisser
```

## Nästa steg

1. Speltesta prototypen — särskilt auto-siktet mot pendelpilen.
2. Fas 1: den handskrivna markkontrollern, scanning-menyn, profiler, förmåga 1–2.
3. Boka det första speltestet med målgruppen. Datumet driver arbetet.

## Not om stora filer

Källfiler för grafik och ljud (`.kra`, `.aseprite`, `.wav`, skanningar) bör läggas i
Git LFS när de börjar komma in. Skisserna i `concept/` är nedskalade och ligger direkt
i repot; originalen hör hemma i LFS eller separat lagring.
