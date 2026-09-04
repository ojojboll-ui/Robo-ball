extends Node
## Tillgänglighetsinställningar.
##
## Allt som påverkar tempo, styrning och hjälp ligger här — aldrig hårdkodat ute i
## spelkoden. Prototypen använder en delmängd av matrisen i docs/ACCESSIBILITY.md;
## resten kommer i fas 1 tillsammans med profiler och scanning-menyn.

signal changed

const PATH := "user://settings.json"

enum ControlVariant {
	CLASSIC,      ## tryck för att sikta, tryck för att hoppa
	HOLD_RELEASE, ## håll för att sikta, släpp för att hoppa
	AUTO_AIM,     ## ett tryck — spelet väljer vinkeln
}

## Tempo
var game_speed := 1.0          ## 0.25–1.0, skalar hela världen
var walk_speed := 1.0          ## 0.5–1.5, bara RB:s gångfart
var aim_sweep_speed := 1.0     ## 0.1–2.0, pilens pendelhastighet
var slowmo := 0.2              ## 0.05–1.0, speltid under sikte
var aim_timeout := 0.0         ## sekunder, 0 = aldrig
var input_debounce := 0.15     ## sekunder, filtrerar skakningar och dubbeltryck

## Styrning
## Håll den som int, inte som enum-typ: den sätts från JSON och stegas i
## utvecklarpanelen, och GDScripts statiska typning gillar inte int → enum.
var control_variant: int = ControlVariant.CLASSIC
var aim_steps := 0             ## 0 = mjuk pendel, annars antal diskreta vinklar
## Pilens spann i grader. 0 = rakt höger, 90 = rakt upp, 180 = rakt vänster.
## Bågen startar alltid i den ände som ligger åt det håll RB går, och pendlar
## därifrån — går han åt höger börjar den vågrätt framåt och sveper upp och över.
var aim_min_deg := 0.0
var aim_max_deg := 180.0
var trajectory_preview := true
var air_jumps := 1             ## extra hopp i luften: 0 = av, 1 = dubbelhopp
var ledge_guard := true        ## vänd vid kanter i stället för att ramla

## Effekter
var effects := true

## Fysik och känsla. Ligger här och inte som konstanter i koden av två skäl:
## de ska gå att skruva på mitt i ett speltest, och flera av dem är i praktiken
## tillgänglighetsinställningar — hoppkraft och gravitation avgör hur stor
## marginal spelaren har när hen siktar.
var jump_power := 700.0        ## 300–1100
var rb_gravity := 1400.0       ## 600–2400
var wall_bounce := 0.4         ## 0.0–0.9, hur mycket RB studsar på väggar
## Hur mycket av farten *in i* underlaget som blir fart *längs* det vid landning.
## Vid 0 kastas den bort helt — då stannar ett hopp ner i en backe nästan tvärt,
## vilket är vad ett klibbigt föremål gör. En boll som landar i en backe får i
## stället sin rörelse omdirigerad nedför, och det är den här siffran som styr
## hur mycket. Effekten växer med lutningen och är noll på plan mark.
var landing_redirect := 0.6
var push_force := 0.55         ## 0.1–2.0, hur hårt RB knuffar lösa föremål
var crate_mass := 1.2          ## 0.2–5.0
var crate_break_speed := 380.0 ## 100–900, farten som krävs för att krossa
var crate_friction := 0.6      ## 0.0–1.0
var crate_bounce := 0.0        ## 0.0–0.9
var crate_gravity := 1.0       ## 0.2–3.0, gravitationsskala för lösa föremål

## Saknade reglage tidigare, och alla tre bidrar till hur "flytande" han känns.
var ground_stick := 150.0      ## hur hårt han trycks mot underlaget
var walk_accel := 900.0        ## hur snabbt benen når full gångfart
var leg_stiffness := 220.0     ## benfjädringens styvhet
var leg_damping := 22.0        ## benfjädringens dämpning
var tuck_speed := 6.5          ## hur snabbt benen viks in, högre = snabbare
## Ser han att marken han är på väg mot är för brant för benen drar han in dem
## redan i luften och landar som boll. Annars landar han på fötterna först och
## tappar farten innan rullningen hinner börja.
var tuck_before_landing := true
var tuck_lookahead := 0.30     ## sekunder framåt han känner av landningen

## Markkontrollern och rullningen
var leg_max_slope := 43.0      ## grader, brantast benen klarar innan de åker in
var roll_max_slope := 62.0     ## grader, brantast han håller sig kvar som boll
var roll_friction := 30.0      ## px/s², rullmotstånd
## Över den här farten drar han in benen oavsett hur flack marken är. 0 = av.
## Det är den mekanik som bär de första pusslen, innan han hittat benen: springer
## han fort nog blir han en boll, och då gäller andra regler.
var roll_speed := 0.0
var auto_roll := true          ## dra in benen automatiskt i branta lutningar
var keep_ball_airborne := true ## är han boll när han lämnar marken förblir han boll
var crest_release := true      ## släpper underlaget på krön där farten inte kan följa det
var level_index := 0
var panel_tab := 0            ## vilken flik i inställningspanelen som var öppen

## Grundvärdena fångas innan sparfilen läses, så att panelen kan återställa allt
## utan att någon behöver skriva upp dem en andra gång.
var _defaults: Dictionary = {}

func _ready() -> void:
	_defaults = as_dict()
	load_settings()

func reset_to_defaults() -> void:
	apply(_defaults)
	save_settings()

func as_dict() -> Dictionary:
	return {
		"game_speed": game_speed,
		"walk_speed": walk_speed,
		"aim_sweep_speed": aim_sweep_speed,
		"slowmo": slowmo,
		"aim_timeout": aim_timeout,
		"input_debounce": input_debounce,
		"control_variant": int(control_variant),
		"aim_steps": aim_steps,
		"aim_min_deg": aim_min_deg,
		"aim_max_deg": aim_max_deg,
		"roll_speed": roll_speed,
		"trajectory_preview": trajectory_preview,
		"air_jumps": air_jumps,
		"ledge_guard": ledge_guard,
		"effects": effects,
		"jump_power": jump_power,
		"rb_gravity": rb_gravity,
		"wall_bounce": wall_bounce,
		"landing_redirect": landing_redirect,
		"push_force": push_force,
		"crate_mass": crate_mass,
		"crate_break_speed": crate_break_speed,
		"crate_friction": crate_friction,
		"crate_bounce": crate_bounce,
		"crate_gravity": crate_gravity,
		"ground_stick": ground_stick,
		"walk_accel": walk_accel,
		"leg_stiffness": leg_stiffness,
		"leg_damping": leg_damping,
		"tuck_speed": tuck_speed,
		"tuck_before_landing": tuck_before_landing,
		"tuck_lookahead": tuck_lookahead,
		"leg_max_slope": leg_max_slope,
		"roll_max_slope": roll_max_slope,
		"roll_friction": roll_friction,
		"auto_roll": auto_roll,
		"keep_ball_airborne": keep_ball_airborne,
		"crest_release": crest_release,
		"level_index": level_index,
		"panel_tab": panel_tab,
	}

func apply(data: Dictionary) -> void:
	game_speed = float(data.get("game_speed", game_speed))
	walk_speed = float(data.get("walk_speed", walk_speed))
	aim_sweep_speed = float(data.get("aim_sweep_speed", aim_sweep_speed))
	slowmo = float(data.get("slowmo", slowmo))
	aim_timeout = float(data.get("aim_timeout", aim_timeout))
	input_debounce = float(data.get("input_debounce", input_debounce))
	control_variant = int(data.get("control_variant", control_variant))
	aim_steps = int(data.get("aim_steps", aim_steps))
	aim_min_deg = float(data.get("aim_min_deg", aim_min_deg))
	aim_max_deg = float(data.get("aim_max_deg", aim_max_deg))
	roll_speed = float(data.get("roll_speed", roll_speed))
	trajectory_preview = bool(data.get("trajectory_preview", trajectory_preview))
	air_jumps = int(data.get("air_jumps", air_jumps))
	ledge_guard = bool(data.get("ledge_guard", ledge_guard))
	effects = bool(data.get("effects", effects))
	jump_power = float(data.get("jump_power", jump_power))
	rb_gravity = float(data.get("rb_gravity", rb_gravity))
	wall_bounce = float(data.get("wall_bounce", wall_bounce))
	landing_redirect = float(data.get("landing_redirect", landing_redirect))
	push_force = float(data.get("push_force", push_force))
	crate_mass = float(data.get("crate_mass", crate_mass))
	crate_break_speed = float(data.get("crate_break_speed", crate_break_speed))
	crate_friction = float(data.get("crate_friction", crate_friction))
	crate_bounce = float(data.get("crate_bounce", crate_bounce))
	crate_gravity = float(data.get("crate_gravity", crate_gravity))
	ground_stick = float(data.get("ground_stick", ground_stick))
	walk_accel = float(data.get("walk_accel", walk_accel))
	leg_stiffness = float(data.get("leg_stiffness", leg_stiffness))
	leg_damping = float(data.get("leg_damping", leg_damping))
	tuck_speed = float(data.get("tuck_speed", tuck_speed))
	tuck_before_landing = bool(data.get("tuck_before_landing", tuck_before_landing))
	tuck_lookahead = float(data.get("tuck_lookahead", tuck_lookahead))
	leg_max_slope = float(data.get("leg_max_slope", leg_max_slope))
	roll_max_slope = float(data.get("roll_max_slope", roll_max_slope))
	roll_friction = float(data.get("roll_friction", roll_friction))
	auto_roll = bool(data.get("auto_roll", auto_roll))
	keep_ball_airborne = bool(data.get("keep_ball_airborne", keep_ball_airborne))
	crest_release = bool(data.get("crest_release", crest_release))
	level_index = int(data.get("level_index", level_index))
	panel_tab = int(data.get("panel_tab", panel_tab))
	changed.emit()

func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Kunde inte spara inställningar: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(as_dict(), "\t"))

## På webben ligger user:// i webbläsarens IndexedDB och kan rensas när som helst.
## Därför måste allt här tåla att komma tillbaka tomt — och därför ska profiler gå
## att exportera som fil (fas 1).
func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		var data: Dictionary = parsed
		# Engångsflytt: siktets spann var en kort tid 90–370 grader. Sparade
		# profiler med exakt de värdena får de nya i stället, annars sitter
		# gamla speltest fast i en inställning vi övergett.
		if is_equal_approx(float(data.get("aim_min_deg", 0.0)), 90.0) \
				and is_equal_approx(float(data.get("aim_max_deg", 0.0)), 370.0):
			data.erase("aim_min_deg")
			data.erase("aim_max_deg")
		# Samma sak för benens gräns: 38 grader var en gissning, 43 är
		# provspelat. En profil som står kvar på den gamla siffran bara för att
		# den råkade sparas är inte ett val någon gjort.
		if is_equal_approx(float(data.get("leg_max_slope", 0.0)), 38.0):
			data.erase("leg_max_slope")
		apply(data)

func notify_changed() -> void:
	changed.emit()
