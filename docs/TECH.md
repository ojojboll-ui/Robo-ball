# Robo Ball — teknik

## 1. Beslutat

**Godot 4, GDScript, webben som förstahandsplattform.** Godots inbyggda 2D-fysik för
världen, en handskriven markkontroller för RB. Se DECISIONS.md.

Webbvalet är det som styr allt annat i det här dokumentet: inget kräver installation,
spelet startar från en länk i skolan eller på habiliteringen, och därför är GDScript
språket (webbexport för C#/.NET har legat efter) och inbyggd fysik fysiken (GDExtensions
är krångligare i webbygget).

## 2. Motorval — varför Godot

| Alternativ | För | Emot | Dom |
|---|---|---|---|
| **Godot 4** | gratis och MIT-licensierad (inga royalties, inga licensvillkor som ändras), utmärkt 2D som inte är påklistrat på en 3D-motor, inbyggd 2D-ljussättning med skuggkastare (ficklampan), litet nedladdningsbart bygge, exporterar till Windows/macOS/Linux/webb/mobil, öppen källkod → vi kan patcha motorn om ett tillgänglighetsbehov kräver det | mindre färdigt ekosystem än Unity, en del plugins är enmansprojekt | **Ja** |
| Unity | störst ekosystem, Box2D inbyggt, mycket färdig kod att köpa | licensmodellen har ändrats ensidigt förut → risk för ett projekt som ska leva länge och kanske delas ut gratis; tyngre pipeline | Nej |
| GameMaker | snabbt för 2D | svag stelkroppsfysik, svårare att bygga egna tillgänglighetslager | Nej |
| Egen motor i webben (TypeScript + PixiJS + Planck/Rapier) | maximal kontroll över input och tillgänglighet, körs överallt utan installation, fungerar med hjälpmedel som redan finns i webbläsaren | vi bygger editor, kartverktyg, partiklar, ljud, sparsystem själva — månader innan första hoppet känns bra | Nej som huvudspår |

Öppen källkod är dessutom ett argument i sig här: om projektet söker medel från t.ex.
Arvsfonden är "resultatet blir fritt tillgängligt och går att vidareutveckla av andra"
inte en teknikdetalj utan en del av ansökan.

### GDScript, inte C#
Din C#-vana talar för C#, och C# i Godot är i sig ett fullgott förstahandsspråk. Men
webben är valt, och där är GDScript det mogna spåret. Beslutet är taget för att slippa
ett omtag mitt i projektet — prototypen skrivs alltså direkt i GDScript.

Praktiskt är övergången mindre än den låter: GDScript är statiskt typat när man vill
(`var x: float`), har klasser, signaler och samma nodträd. Skriv typat från början —
det ger både bättre prestanda och den kompilatorhjälp du är van vid.

## 3. Fysikarkitektur

Det här är projektets svåraste tekniska beslut, så det förtjänar detaljer.

### Varför RB inte ska vara en RigidBody
Det frestande är att göra RB till en cirkelformad stelkropp och låta motorn sköta allt.
Det ger dålig känsla: hastigheten blir svårkontrollerad, han studsar och snurrar
oförutsägbart, och Sonic-loopar fungerar inte alls. Alla spel med den här sortens
rullande hjälte (Sonic, Rayman-boll-sektioner, Kirby-baller) använder en egen
markkontroller.

### RB:s tre lägen

```
GROUNDED   : hastighet lagras som skalär "markfart" längs ytans tangent.
             Varje tick: shapecast nedåt → hitta yta + normal → projicera
             rörelsen längs normalen → applicera gravitationens
             tangentkomponent (fart uppför backe, fart nedför).
             Släpper vid för låg fart i brant lutning ("gravitationsgräns"),
             vilket ger loopar gratis: har man fart klarar man loopen,
             annars ramlar man av.
AIRBORNE   : v += g·dt; position += v·dt. Ingen styrning. Kollision via
             shapecast; vid träff antingen landning (projicera in i
             GROUNDED) eller studs (reflektera med restitution).
AIMING     : RB fryst; bara pilen uppdateras. Världen kör med time_scale.
```

### Världens fysik
Allt destruerbart och gungande är riktiga `RigidBody2D`: lådor, plankstaplar,
stenblock, trapetser (`PinJoint2D`), vippbrädor. Skörhet modelleras som
"tål X joule" — vid träff jämförs `0.5·m·v²` mot tröskeln, över tröskeln byts objektet
mot sina bitar med ärvd rörelsemängd. Det är samma trick som Angry Birds använder och
det är billigt.

### Godots fysik, inte Box2D
Godots inbyggda 2D-fysik räcker med god marginal för det här, och den är dessutom det
säkra kortet i webbygget: GDExtensions (som `godot-box2d` och `godot-rapier2d`) är
mer bräckliga där. Vi håller dem som reservplan om ett desktop-spår någon gång behöver
stabilare staplar eller determinism — bytet är rader i projektinställningarna, inte en
omskrivning.

### Slow motion
Använd **inte** `Engine.time_scale` rakt av — den saktar ner allt, inklusive UI, ljud
och siktpilen, och gör slow motion-styrkan omöjlig att koppla loss från spelkänslan.
Lägg i stället en egen `WorldClock` som gameplay-noder läser sitt delta ifrån, medan
UI och siktpil kör på riktig tid. Slow motion-faktorn blir då ett rent
tillgänglighetsreglage (1.0 = av, 0.05 = nästan pausad).

## 4. Inputarkitektur — projektets viktigaste kodbeslut

Hela spelet får bara känna till **en** händelse:

```gdscript
signal_pressed   # "spelaren gjorde något"
signal_released  # (behövs bara för håll & släpp-varianten)
```

Allt annat är adaptrar som mynnar ut i den signalen:

| Källa | Adapter | Kommentar |
|---|---|---|
| Tangentbord (valfri tangent) | Godot input | de flesta kontaktmanöverdon (switchar) emulerar tangentbord |
| Mus/pekskärm (klick var som helst) | Godot input | ögonstyrningsprogram emulerar oftast musklick via dwell |
| Handkontroll (valfri knapp) | Godot input | inkl. Xbox Adaptive Controller |
| Blås/sug, blink, huvudmus | via HID-emulering | ingen egen kod behövs |
| Ögonstyrning (Tobii m.fl.) | i steg 1: hjälpmedlets egen dwell-klick. I steg 2: eget plugin för blickposition | se nedan |
| Ljud (rop/blås i mikrofon) | egen adapter, tröskel + brusgolv | överraskande populärt hos den som inte kan använda händer |

**Insikten:** eftersom praktiskt taget alla kommersiella hjälpmedel redan emulerar
tangentbord, mus eller handkontroll, så fungerar spelet med dem *utan att vi skriver
en rad hjälpmedelskod* — förutsatt att vi accepterar "vilken tangent som helst" och
"klick var som helst på skärmen". Det är gratis räckvidd, och det ska stå i kravet
från dag ett.

Ögonstyrning som *riktad* input (titta där du vill hoppa, i stället för pendelpil) är
en senare, större sak: den kräver plattformsspecifikt SDK och ett helt eget siktläge.
Lägg den i fas 4+, men designa siktsystemet så att "vinkeln kommer utifrån" är en
möjlig källa redan nu.

Lägg också in **inmatningsloggning** (anonymt, lokalt, avstängbart): tid mellan signaler,
missade hopp, var man fastnar. Utan den datan blir tillgänglighetsjusteringar gissningar.

## 5. Färdiga byggblock att använda

* **Fysik:** Godot inbyggd → vid behov `godot-box2d` eller `godot-rapier2d` (GDExtension).
* **Kamera:** Phantom Camera (Godot-addon) i stället för egen kameralogik — mjuk följning,
  zoner, look-ahead. Kameran är extra viktig här: spelaren styr inte, så kameran måste
  visa vad som kommer.
* **Banredigering:** Godots TileMapLayer räcker; Tiled + importplugin om vi vill ha
  externa banbyggare (t.ex. en pedagog som gör egna banor — värt att fundera på).
* **Animation:** hand­ritat i Krita/Aseprite; Godots AnimationPlayer + skelett för RB:s ben.
* **Ljud:** Godots bussar räcker; Audacity/Reaper för produktion. Ljud är ett
  tillgänglighetsverktyg här, inte dekor — varje viktig händelse behöver ett eget ljud.
* **Ljus/mörker:** `PointLight2D` + `LightOccluder2D` ger ficklampan direkt i motorn.
* **Sparning/inställningar:** eget litet JSON-lager (profiler, se ACCESSIBILITY.md).
* **Beteenden för fiender:** Beehave (behavior trees) om fienderna växer i komplexitet;
  börja med enkla tillståndsmaskiner.

## 6. Projektstruktur och arbetsflöde

```
robo-ball/
  docs/            # denna dokumentation
  game/            # Godot-projektet
    core/          # WorldClock, InputSignal, Save, Settings, Profiles
    actor/         # RB: markkontroller, siktläge, förmågor
    world/         # tiles, destruerbara objekt, faror, fiender
    ui/            # scanning-meny, HUD, karta
    levels/
    art/  audio/
  tools/           # bygg-/exportskript, banverktyg
```

* Git + **Git LFS** för bild- och ljudkällor (skanningar blir stora).
* GitHub Actions som bygger Windows- och webbexport på varje tagg och laddar upp till
  itch.io (butler) — testbygge i händerna på testarna samma dag som en ändring görs.
* Källfiler (Krita, ljudprojekt) i repo eller i molnmapp, men *versionera* dem.

## 7. Webbexport — vad valet faktiskt kostar

Webben är rätt beslut, men den har sina egna fällor. Ta dem i fas 0, inte i fas 4:

* **Headers.** Med trådstöd kräver Godots webbygge `SharedArrayBuffer`, vilket i sin
  tur kräver `Cross-Origin-Opener-Policy: same-origin` och
  `Cross-Origin-Embedder-Policy: require-corp` från servern. GitHub Pages kan inte sätta
  headers alls, och itch.io har visserligen en inställning — men **fas 0 exporterar utan
  trådstöd** (beslut 8) just för att bygget ska gå att lägga var som helst. Frågan tas
  upp igen den dag prestandataket biter.
* **Fokus i iframe.** I en inbäddad spelare måste sidan klickas innan tangentbordet når
  spelet. För ett enknappsspel är det ett tillgänglighetsproblem, inte en detalj: se till
  att spelet tar fokus automatiskt, att klick var som helst räknas som signal, och att
  helskärmsläget är lätt att nå.
* **Startstorlek.** Bygget ska vara litet nog att ladda på ett skolnätverk. Sikta under
  50 MB totalt, komprimera bilder och ljud, och visa en laddningsskärm som inte kräver
  läsning.
* **Sparning.** `user://` hamnar i webbläsarens IndexedDB och kan rensas av användaren
  eller av skolans IT. Därför måste profiler gå att **exportera som fil** (nedladdning)
  och importera igen — det är också vad som gör att en arbetsterapeut kan ställa in
  hemma och skicka med filen till skolan.
* **Skärmläsare ser ingenting.** En canvas är en svart låda för webbläsarens
  tillgänglighetsverktyg. Vi kan alltså inte luta oss mot webbens inbyggda stöd — vårt
  eget scanning-UI och den uppläsning vi bygger själva är hela tillgängligheten.
* **Desktop-bygget följer med gratis.** Samma projekt exporterar till Windows, macOS och
  Linux. Ta med Windows-bygget i CI från dag ett, som reserv när webben strular hos en
  testare.

## 8. Prestandabudget

Måltak: 60 fps i webbläsaren på en Chromebook och på en sju år gammal bärbar dator med
integrerad grafik. Det är målgruppens hårdvara, inte en speldator. Det betyder:
tak för antal aktiva stelkroppar per skärm (~80), destruktionsbitar med livslängd, och
partiklar som är avstängbara (vilket ändå krävs av tillgänglighetsskäl).
