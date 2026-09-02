# Robo Ball — projektplan

## 1. Mål

Ett färdigt, säljbart 2D-metroidvania på **ca 90 minuters speltid**, spelbart **i
webbläsaren utan installation**, som går att ta sig igenom med en enda signal — med
grafik och fysikkänsla som håller kommersiell nivå, och med tillgänglighetsinställningar
som gör att målgruppen faktiskt kan spela det själva i stället för att titta på när
någon annan gör det.

Den korta speltiden är ett medvetet val: den halverar tiden till release och når barnen
ett år tidigare. Världen byggs så att den går att förlänga — v1 är en förkortning av
planen, inte en annan design.

Sekundärt mål: att inställningslagret och inputlagret är återanvändbart och öppet, så
att andra utvecklare kan göra samma sak billigare.

Låsta beslut: **Godot 4, GDScript, webben först, eget repo `robo-ball`, ca 90 minuter,
fyra förmågor.** Se DECISIONS.md.

## 2. Arbetssätt

* **Vertikal skiva före bredd.** Ett litet område som är helt färdigt säger mer om
  projektet än sex halvfärdiga.
* **Speltest med målgruppen i varje fas**, från gråboxprototypen och framåt.
* **Tillgänglighet byggs in i systemen, inte ovanpå.** Varje ny mekanik ska svara på
  "hur ställs den in?" innan den byggs klart.
* **Alltid spelbart.** `main` ska alltid gå att exportera och skicka till en testare.

## 3. Faser

### Fas 0 — Beslut och känsla (3–4 veckor)
Syfte: ta reda på om kärnan är rolig innan vi bygger något runt den.

* Sätta upp repot `robo-ball`, Godot-projektet och CI som exporterar ett webbygge.
* **Verifiera webbkedjan tidigt:** bygge på riktig hosting med rätt COOP/COEP-headers,
  test på Chromebook och surfplatta, tangentbordsfokus i inbäddad spelare. Går inte det
  att lösa i fas 0 är det bättre att veta nu än i fas 4.
* Gråboxprototyp: auto-gång, vändning, siktläge med pendelpil, slow motion,
  ballistiskt hopp, landning. Ingen grafik, en enda testbana.
* WorldClock och InputSignal på plats från början — det är dessa två som allt annat
  bygger på.
* En hink med lådor att krossa, för att känna på Angry Birds-biten.
* **Milstolpe:** någon som aldrig sett spelet kan ta sig genom en hinderbana med
  mellanslag som enda knapp — i en webbläsare, via en länk — och tycker det är kul.
  Första speltestet med 1–2 barn.
* **Beslutspunkt:** känns hoppet bra? Om pendelpilen är frustrerande måste vi lösa det
  här, inte i fas 3.

### Fas 1 — Systemgrunden (2–3 månader)
Syfte: bygga det som är dyrt att lägga till i efterhand.

* Markkontrollern på riktigt: ramper, lutningar, en fungerande loop, vändlogik,
  kantskydd.
* Fysiklagret: destruerbara objekt med energitröskel, trapetser, vippbrädor.
* Inputadaptrar för alla källor i TECH.md, plus inmatningslogg.
* Inställnings- och profilsystem, sparning, scanning-UI för menyer.
* Förmågesystem (ramverk) + förmåga 1–2 (rulla, ben).
* Kamera (Phantom Camera), grundläggande ljudbussar.
* **Milstolpe:** hela inställningsmatrisen i ACCESSIBILITY.md går att ändra i spelet och
  påverkar något synligt. Genomgång mot Game Accessibility Guidelines.

### Fas 2 — Vertikal skiva (2–3 månader)
Syfte: ett område i färdig kvalitet, som också blir vårt visningsmaterial.

* Kraschplatsen + grottorna, 25–30 minuters spel — alltså en tredjedel av hela v1.
* Förmåga 3 (spikar) och 4 (ficklampan) med sina grindar.
* Färdig grafik i konceptskissernas stil, animerad RB, ljudbild, en mellansekvens.
* Två fiendetyper, en minichef.
* **Milstolpe:** speltest med hela referensgruppen (5–8 barn). Trailer-dugligt material.
* **Beslutspunkt:** här vet vi vad ett område kostar i tid, och kan räkna om resten av
  planen på riktiga siffror i stället för gissningar.

### Fas 3 — Resten av världen (3–4 månader)
* Två biotoper till: skrotupplaget (mycket förstörbar fysik) och rampdalen (fart).
* Genvägar tillbaka, kartsystem, samlarföremål.
* Fiendegalleri, en chef.
* Löpande speltest.

### Fas 4 — Tornet och polering (2 månader)
* Sluttornet: sammanfattar alla förmågor, slutchef, avslutning.
* Balansering av alla assistlägen — varje läge ska klara hela spelet.
* Prestandaarbete mot budgeten i TECH.md.
* Lokalisering svenska/engelska, uppläst text.
* Vuxenläget (inställningsguide för föräldrar och personal).

### Fas 5 — Release och efter (1–2 månader + löpande)
* Webbversionen är huvudutgåvan: egen sida eller itch, med en länk som går att skicka
  till en lärare och som fungerar direkt. Desktop-bygget på Steam och itch.
* Butikssidor med konkret tillgänglighetsbeskrivning — för den här målgruppen är det
  köpbeslutet.
* Pressarbete riktat mot både speltidningar och funktionsrättsrörelsen — det här är en
  berättelse som har publik.
* Efter release: v2 med resterande förmågor och biotoper, ögonstyrning som riktad input,
  fler styrningsvarianter, ev. banredigerare för pedagoger.

### Total tidsuppskattning
Cirka **10–14 månader på heltid för en person** för 90-minutersutgåvan, väsentligt
längre på fritiden. Med deltidsgrafiker och deltidsljud i fas 2–4 pressas kalendertiden
mot 8–10 månader. Den fulla världen (3–4 timmar, alla åtta förmågor) är en fortsättning
på samma kodbas och samma karta — räkna ytterligare 8–12 månader för den, som v2.

## 4. Roller

| Roll | Behov | Kommentar |
|---|---|---|
| Programmering | genomgående | fysik, systemarkitektur, tillgänglighetslager |
| Speldesign / banor | från fas 1 | banbyggande i ett spel utan styrning är en egen konstform |
| 2D-grafik och animation | tyngdpunkt fas 2–4 | konceptskisserna finns redan, stilen är satt |
| Ljud och musik | fas 2–4 | ljud bär mycket av tillgängligheten |
| Tillgänglighetsrådgivning | löpande | arbetsterapeut/specialpedagog, gärna betald konsulttid |
| Testledning | varje fas | boka, genomföra och tolka speltest med barnen |

Du täcker sannolikt de två första själv. Den viktigaste externa personen är
tillgänglighetsrådgivaren — den rollen sparar mest omarbete.

## 5. Risker

| Risk | Konsekvens | Motmedel |
|---|---|---|
| Enknappsstyrningen blir tråkig i längden | projektet dör i fas 3 | fas 0 avgör detta; djupet ska komma från *världen* och förmågorna, inte från inmatningen |
| Pendelpilen känns som ett lotteri | frustration hos just den målgrupp vi bygger för | förhandsbana, siktehjälp, diskreta vinkelsteg, auto-sikte — alla finns i planen |
| Markkontroller + stelkroppsvärld krockar (RB fastnar, skakar, skjuts genom väggar) | klassisk tidstjuv | tydlig gräns mellan lägena, shapecast i stället för punktkollision, "fastnat"-detektor som återställer |
| Scope creep (fler förmågor, större värld) | aldrig färdig | förmågelistan är låst efter fas 2; nya idéer går till "efter release" |
| Speltest med målgruppen är logistiskt tungt | vi bygger på gissningar | bygg relationer med habilitering/särskola redan under fas 0, inte när vi behöver testarna |
| Webbexport kraschar i språkvalet | ombyggnad | verifiera i fas 0, inte senare |
| Ensamprojekt tappar fart | vanligaste dödsorsaken | kvartalsvisa speltest ger yttre deadlines och den bästa sortens motivation |

## 6. Finansiering (svenska spår att undersöka)

* **Allmänna Arvsfonden** — finansierar nyskapande projekt för barn, unga och personer
  med funktionsnedsättning. Det här projektet ligger mitt i deras uppdrag. Kräver
  normalt en ideell organisation som huvudman, så samarbete med en förening
  (t.ex. inom funktionsrättsrörelsen) är en förutsättning värd att lösa tidigt.
* **Postkodstiftelsen** och liknande stiftelser.
* **Nordisk kulturkontakt / Creative Europe** för spelutveckling.
* **Kommersiellt:** utgivare inriktade på tillgängliga eller "wholesome" spel; plattformarnas
  egna tillgänglighetsprogram (Xbox har haft initiativ på området).
* Kombinationen "socialt uppdrag + kommersiellt spel" är stark i ansökningar, men kräver
  att man är tydlig med båda delarna. Verifiera aktuella villkor innan ansökan.

## 7. Kvarvarande öppna frågor

Motor, språk, plattform, repo och omfattning är beslutade (DECISIONS.md). Kvar:

1. **Ensam eller med hjälp?** Grafik och ljud är där extern hjälp ger mest per krona.
   Den viktigaste externa personen är ändå en arbetsterapeut som rådgivare — den rollen
   sparar mest omarbete.
2. **Speltestare:** vilka kontakter finns redan från ditt arbete med barnen? Det är
   projektets mest värdefulla tillgång, och det som avgör om tillgängligheten blir
   riktig eller påhittad.
3. **Finansiering:** ska vi söka Arvsfonden? I så fall behövs en förening som huvudman,
   och det tar tid att ordna — beslutet bör tas under fas 0, inte efter.
4. **Affärsmodell:** gratis på webben och betalt på Steam, eller betalt överallt? Påverkar
   både räckvidd och vilka bidrag som är möjliga.

## 8. Nästa konkreta steg

1. Skapa repot `robo-ball`, flytta över dessa dokument.
2. Godot 4-projekt + CI som bygger webbexport och Windows-export på varje push.
3. Verifiera webbkedjan på riktig hosting (headers, Chromebook, surfplatta, fokus).
4. Bygga fas 0-prototypen: auto-gång, siktläge, ballistiskt hopp, en hög lådor.
5. Boka första speltestet innan prototypen ens är klar — datumet driver arbetet.
