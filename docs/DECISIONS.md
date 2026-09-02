# Beslutslogg

Beslut som är fattade och som resten av planen vilar på. Ändras bara medvetet, och då
med en ny rad här.

| # | Datum | Beslut | Motivering | Status |
|---|---|---|---|---|
| 1 | 2026-09 | **Spelet får ett eget repo, `robo-ball`.** | Ett Godot-projekt hör inte hemma i TiXL-forken. Dokumentationen ligger kvar här tills repot är uppsatt, och flyttar då med. | Beslutat, ej genomfört |
| 2 | 2026-09 | **Motor: Godot 4.** | Gratis och MIT, stark 2D, inbyggd 2D-ljussättning för ficklampan, exporterar till webben, öppen källkod (väger även i bidragsansökan). | Beslutat |
| 3 | 2026-09 | **Webben är förstahandsplattform.** | Ingen installation. Skolor och habiliteringar får sällan installera program — webbversionen är skillnaden mellan att spelet används och inte. Desktop-bygge följer med på köpet. | Beslutat |
| 4 | 2026-09 | **Språk: GDScript.** | Följer av beslut 3: webbexport är mognare för GDScript än för C#/.NET. C#-vanan får stå tillbaka. | Beslutat |
| 5 | 2026-09 | **Fysik: Godots inbyggda 2D-fysik.** | Räcker med marginal, och undviker GDExtensions som krånglar i webbexport. Box2D/Rapier hålls som reservplan för ett eventuellt desktop-spår. | Beslutat |
| 6 | 2026-09 | **Första utgåvan är ca 90 minuter lång.** | Halverar tiden till release och når målgruppen ett år tidigare. Världen byggs så att den går att förlänga — v1 är en förkortning, inte en annan design. | Beslutat |
| 7 | 2026-09 | **Förmågor i v1: rulla, ben, spikar, dubbelhopp.** | Täcker horisontell, vertikal och "utanför golvet"-rörelse plus räckvidd. Ficklampan, hårt skal, kroken, gummiskal och turbon skjuts till v2. Förstörbar fysik finns ändå från start — skalet höjer bara tröskeln, det skapar den inte. | Reviderat, se rad 10 |
| 8 | 2026-09 | **Webbygget exporteras utan trådstöd.** | Med trådar kräver Godots webbygge `SharedArrayBuffer`, alltså COOP/COEP-headers från servern — och GitHub Pages kan inte sätta headers. Utan trådar går bygget att lägga var som helst, vilket är hela poängen med webben som plattform. Priset är lägre prestandatak; tas upp igen om vi flyttar till egen hosting eller itch. | Beslutat |
| 9 | 2026-09 | **WorldClock styr Engine.time_scale i fas 0.** | Enklaste vägen till korrekt slow motion även för stelkroppar. Priset är att UI och timers också saktas ner; siktpilen kompenserar via `WorldClock.unscaled()`. Byts mot ett eget delta i fas 1 — anroparna behöver inte ändras, vilket är hela poängen med att allt går genom WorldClock. | Beslutat, revideras i fas 1 |
| 10 | 2026-09 | **Dubbelhoppet ersätter ficklampan i v1.** | Speltest av prototypen: dubbelhoppet är en rörelseförmåga och ändrar vad varje hopp kan nå, medan ficklampan bara öppnar en sorts rum. Det ger mer per arbetstimme i en kort första utgåva. Dubbelhoppet klarar dessutom förmågekravet utan invändningar — det använder exakt samma två tryck, mitt i luften i stället för på marken, och lägger alltså till räckvidd utan att lägga till inmatning. Ficklampan flyttas till v2 tillsammans med grottorna. | Beslutat |
| 11 | 2026-09 | **RB knuffar aldrig föremål som ligger under honom.** | Att göra det tryckte lådan ner i marken, marken tryckte tillbaka, och fysikmotorn löste överlappet genom att kasta ut RB uppåt bildruta efter bildruta. Dessutom har hans förflyttning ett tak per bildruta: flyttas han längre än farten tillåter är det motorn som trycker, inte spelet, och överskottet kapas. | Beslutat |
