# Robo Ball — tillgänglighet

Det här dokumentet är kravspec, inte önskelista. Punkterna under "Måste" är
acceptanskriterier: ett bygge som bryter mot dem är trasigt, oavsett hur roligt det är.

## 1. Måste (v1)

1. Spelet går att spela från start till slut med **en** signal, utan håll, utan timing
   under 1 sekund (i grundinställning), utan riktning.
2. **Menyer, inställningar, karta, mellansekvenser och pausmeny** går att använda med
   samma enda signal (scanning-UI, se avsnitt 4).
3. Spelet accepterar **vilken tangent, vilken musknapp var som helst på skärmen, valfin
   handkontrollsknapp och skärmtryck var som helst** som samma signal.
4. Inget innehåll är låst bakom en svårighetsgrad. Assistlägen låser inga slut, inga
   uppgraderingar, inga achievements.
5. Inget kräver läsning. All text har en ljudmotsvarighet eller en ikon.
6. Ingen skärm blinkar över gränsvärdena för fotokänslig epilepsi, och all skärmskakning
   går att stänga av.
7. Autosparning kontinuerligt; inget framsteg kan gå förlorat av att spelet stängs.

## 2. Inställningsmatris

Alla inställningar ska (a) gå att ändra mitt i spelet, (b) ha en direkt förhandsvisning,
och (c) ingå i profiler som kan sparas per barn.

### Tempo och timing
| Inställning | Spann | Grund |
|---|---|---|
| Spelhastighet globalt | 25 % – 100 % | 100 % |
| RB:s gångfart | 50 % – 150 % | 100 % |
| Siktpilens pendelhastighet | 10 % – 200 % | 100 % |
| Slow motion vid sikte | 5 % – 100 % av speltid | 20 % |
| Timeout i siktläget | 2 s – aldrig | aldrig |
| Fiendernas tempo | 25 % – 100 % | 100 % |
| Inmatningsfördröjning/debounce (mot skakningar och dubbeltryck) | 0 – 2000 ms | 150 ms |
| "Ignorera andra trycket inom" (mot spasticitet) | 0 – 1500 ms | 300 ms |

### Styrning
| Inställning | Alternativ |
|---|---|
| Signalvariant | klassisk / håll & släpp / auto-sikte / två-knapp / scanning-sikte |
| Vinkelspann för pilen | brett / smalt / diskreta steg (3, 5, 7, 9 lägen) |
| Siktehjälp | av / dras mot nåbara mål / helautomatiskt |
| Kantskydd (vänder i stället för att falla) | på / av |
| Autopaus vid inaktivitet | av / 10 s / 30 s / 60 s |
| Ångra hopp (spola tillbaka 3 sekunder) | av / obegränsat |

### Svårighet
| Inställning | Alternativ |
|---|---|
| Skada | normal / halverad / ingen (odödlig) |
| Fiender | normala / passiva / borttagna |
| Fallskada | på / av |
| Kontrollpunkter | normala / täta / "aldrig backa" |

### Syn och ljud
| Inställning | Alternativ |
|---|---|
| Färgblindhetsläge | protanopi / deuteranopi / tritanopi + separat "hög kontrast" |
| Farosignalering | färg + form + ikon + ljud (formen ska aldrig gå att stänga av) |
| Kontrastförstärkning bakgrund/förgrund | av / medel / kraftig (bakgrunden tonas ner) |
| Partiklar och effekter | full / reducerad / av |
| Skärmskakning | 0 – 100 % |
| Blixtar och snabba blinkningar | på / av (av = allt under 3 Hz) |
| Textstorlek | 100 % – 250 %, och läsbart typsnitt-alternativ |
| Uppläsning av all text | på / av |
| Undertexter för alla ljud | på / av, med bakgrundsplatta |
| Ljudbalans (musik / effekter / röst / gränssnitt) | separata reglage |
| Riktningsljud för faror | på / av |
| Enhandsläge för skärm/monoljud | på / av |

## 3. Profiler

Målgruppen är inte "en spelare" utan "det här barnet". Därför:

* Namngivna profiler med bild/ikon (barnet kan känna igen sin egen utan att läsa).
* **Snabbstartsfrågor** vid första start: tre–fyra frågor som besvaras med samma enda
  signal och som sätter en rimlig utgångspunkt ("Ska jag hoppa åt dig? [visar hur det
  ser ut] — Tryck om det känns bra").
* **Förinställningar** som utgångspunkt: *Standard*, *Långsamt*, *Lugnt* (inga fiender,
  ingen skada), *Auto* (spelet siktar), *Låg syn*, *Låg stimulans*.
* Profiler ska gå att **exportera/importera som fil**, så att en arbetsterapeut kan
  ställa in hemma och skicka med inställningen till skolan.
* Ingen inställning gömd bakom "avancerat".

## 4. Scanning-UI (menyer med en knapp)

Menysystemet markerar ett alternativ i taget i tur och ordning; signal väljer det
markerade. Krav:

* Scanhastighet justerbar (0,5 – 5 s per alternativ), och paus efter val.
* Aktuellt alternativ markeras med **ram + storleksändring + ljud**, inte bara färg.
* "Tillbaka" är alltid ett eget alternativ i listan (aldrig en gest eller ett håll).
* Max 6 alternativ per nivå; djupare menyer i stället för längre.
* Efter ett varv utan val: paus, eller långsammare varv (spelaren kanske behöver mer tid).
* Samma system används i kartan (auto-panorering, signal stannar/väljer).

## 5. Testprotokoll

Tillgänglighet som inte har testats med målgruppen är en gissning. Planen:

* **Referensgrupp:** 5–8 barn/unga med olika funktionsnedsättningar (motorik, syn,
  kognition), plus deras arbetsterapeuter/lärare. Sökes via habilitering, särskola,
  och organisationer i området (t.ex. RBU, SPSM:s resurscenter, Furuboda) — verifiera
  vilka som är rätt kanaler.
* **Kadens:** speltest vid slutet av varje fas, minst en gång per kvartal. Första testet
  redan på gråboxprototypen — innan någon grafik finns.
* **Vad vi mäter:** kan hen starta spelet själv? nå första kontrollpunkten? ändra en
  inställning? Hur lång är faktisk tid mellan signal 1 och signal 2 (loggen)? Var
  ger hen upp?
* **Etik:** skriftligt samtycke från vårdnadshavare, inga bilder på barn i material,
  loggdata anonym och lokal, barnet får avbryta när som helst. Ta fram en kort
  samtyckesblankett innan första testet.
* **Referens:** stäm av mot *Game Accessibility Guidelines* (gameaccessibility.com) och
  *Xbox Accessibility Guidelines* — båda är gratis checklistor och sparar oss månader av
  omupptäckt kunskap. Gör en genomgång av dem i slutet av fas 1.

## 6. Utanför spelet

* **Vuxenläge:** en sida för föräldrar/personal som förklarar vilka inställningar som
  finns och vad de gör, med bilder. Många ger upp innan de hittar rätt.
* **Installation:** ett bygge som inte kräver installation (webb eller portabel exe) är
  ofta skillnaden mellan att spelet används i skolan och inte.
* **Butikssidan** ska beskriva tillgänglighetsfunktionerna konkret — Steam har fält för
  det, och för den här målgruppen är det köpbeslutet.
