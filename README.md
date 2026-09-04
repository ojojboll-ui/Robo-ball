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
| Föremål | Lådornas tyngd, tålighet, friktion, studsighet och gravitation, effekter, studsmattornas studs och bukt, samt stängernas och lianernas grepp, dämpning och slow motion |
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

Tre banor, valbara i panelen under *Bana* (eller med F3). Alla tre är verkstäder, inte
nivåer, och i alla tre är marken sammanhängande hela vägen — RB går av sig själv, och en
bana där auto-gången kan leda ner i en avgrund straffar spelaren för att inte trycka.

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
med en matta under, så att man kan gå av kanten och studsa tillbaka upp. Tre hängande
pelare med fasta stänger som sticker ut vågrätt, 185 px över marken: precis inom
räckhåll för ett hopp rakt upp. Och tre lianer, nästan tre gånger så långa som
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
| **Lianen** hänger där den hänger och han får det grepp geometrin ger | behåller farten längs banan: 100 % genom botten av svängen, 79 % snett in |

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
