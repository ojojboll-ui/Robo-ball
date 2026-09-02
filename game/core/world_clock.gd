extends Node
## Speltid, skild från riktig tid.
##
## Allt som hör till världen ska läsa sin hastighet härifrån, aldrig från Engine
## direkt. Slow motion under sikte är inte en effekt utan speltid delat med
## beslutstid — alltså en tillgänglighetsparameter (Settings.slowmo), precis som
## den globala hastigheten (Settings.game_speed).
##
## FAS 0: implementationen sätter Engine.time_scale, vilket är enkelt och ger
## stelkroppar korrekt slow motion gratis. Priset är att UI och timers också
## saktas ner. Siktpilen slipper undan genom att läsa unscaled() nedan.
## FAS 1: byt insidan av den här filen mot ett eget delta som gameplay-noder
## multiplicerar med, så att UI och ljud lämnas helt orörda. Anroparna behöver
## inte ändras — det är hela poängen med att allt går genom WorldClock.

signal slowmo_changed(active: bool)

const BLEND_SPEED := 9.0

var _slowmo := false
var _factor := 1.0

func _ready() -> void:
	process_priority = -100
	Settings.changed.connect(_on_settings_changed)

func _process(delta: float) -> void:
	# Blandningen körs på riktig tid, annars skulle den sakta ner sig själv.
	var target := Settings.slowmo if _slowmo else 1.0
	_factor = lerp(_factor, target, minf(1.0, unscaled(delta) * BLEND_SPEED))
	Engine.time_scale = maxf(0.01, _factor * Settings.game_speed)

## Verklig tid, opåverkad av slow motion och global hastighet.
## Använd för siktpilen, HUD och allt annat som spelaren ska uppleva i normal takt.
func unscaled(delta: float) -> float:
	return delta / maxf(Engine.time_scale, 0.01)

## Hur långsamt världen går just nu, 1.0 = normal fart. Används av HUD och
## effekter; själva rörelsen sköts av det skalade fysik-deltat.
func factor() -> float:
	return _factor

func is_slowmo() -> bool:
	return _slowmo

func set_slowmo(active: bool) -> void:
	if _slowmo == active:
		return
	_slowmo = active
	slowmo_changed.emit(active)

func _on_settings_changed() -> void:
	Engine.time_scale = maxf(0.01, _factor * Settings.game_speed)
