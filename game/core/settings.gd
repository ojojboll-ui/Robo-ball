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
var trajectory_preview := true
var ledge_guard := true        ## vänd vid kanter i stället för att ramla

## Effekter
var effects := true

func _ready() -> void:
	load_settings()

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
		"trajectory_preview": trajectory_preview,
		"ledge_guard": ledge_guard,
		"effects": effects,
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
	trajectory_preview = bool(data.get("trajectory_preview", trajectory_preview))
	ledge_guard = bool(data.get("ledge_guard", ledge_guard))
	effects = bool(data.get("effects", effects))
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
		apply(parsed)

func notify_changed() -> void:
	changed.emit()
