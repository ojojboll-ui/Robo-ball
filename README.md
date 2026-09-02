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

Förproduktion. Ingen kod ännu; fas 0 är nästa steg.

**Låsta beslut:** Godot 4 · GDScript · webben som förstahandsplattform · ca 90 minuters
speltid i första utgåvan · fyra förmågor (rulla, ben, spikar, ficklampan).
Se [docs/DECISIONS.md](docs/DECISIONS.md).

## Dokumentation

| Dokument | Innehåll |
|---|---|
| [docs/DESIGN.md](docs/DESIGN.md) | Speldesign: kärnloop, styrning, förmågor, värld, progression |
| [docs/TECH.md](docs/TECH.md) | Teknikval, arkitektur, fysikmodell, webbexportens fällor |
| [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md) | Tillgänglighetskrav, inställningsmatris, testprotokoll |
| [docs/PROJECTPLAN.md](docs/PROJECTPLAN.md) | Faser, milstolpar, tidsuppskattning, risker, finansiering |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Beslutslogg |
| [concept/](concept/) | Konceptskisser |

## Struktur (planerad)

```
game/       Godot-projektet
  core/     WorldClock, InputSignal, Save, Settings, Profiles
  actor/    RB: markkontroller, siktläge, förmågor
  world/    tiles, destruerbara objekt, faror, fiender
  ui/       scanning-meny, HUD, karta
  levels/   art/   audio/
tools/      bygg- och exportskript
docs/       denna dokumentation
```

## Nästa steg

1. Godot 4-projekt i `game/`, CI som bygger webbexport och Windows-export på varje push.
2. Verifiera webbkedjan på riktig hosting: COOP/COEP-headers, tangentbordsfokus i
   inbäddad spelare, test på Chromebook och surfplatta.
3. Fas 0-prototypen: auto-gång, siktläge med förhandsbana, ballistiskt hopp, en hög
   lådor som rasar.
4. Boka första speltestet innan prototypen är klar.

## Not om stora filer

Källfiler för grafik och ljud (`.kra`, `.aseprite`, `.wav`, skanningar) bör läggas i
Git LFS när de börjar komma in. Skisserna i `concept/` är nedskalade och ligger direkt
i repot; originalen hör hemma i LFS eller separat lagring.
