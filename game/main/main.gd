extends Node2D
## Fas 0 — lekplatsen och rullbanan.
##
## Syftet är fortfarande ett enda: ta reda på om kärnan är rolig, och kunna
## skruva på den medan någon spelar. Banorna är verkstäder snarare än nivåer,
## och allt som påverkar känslan ligger i inställningspanelen i stället för som
## konstanter i koden.

var _level: Level
var _rb: RoboBall
var _hud: Hud
var _panel: TuningPanel
var _crates: Node2D
var _camera: Camera2D
var _hearts := 0
var _flag: Flag
var _celebrate := 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BACKDROP)

	_level = Level.new()
	add_child(_level)

	_crates = Node2D.new()
	add_child(_crates)

	_rb = RoboBall.new()
	_rb.state_changed.connect(_on_state_changed)
	_rb.hurt.connect(_on_hurt)
	_rb.chained.connect(_on_chained)
	add_child(_rb)

	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_EASE
	_camera.zoom = Vector2(1.05, 1.05)
	_camera.limit_left = -120
	_camera.limit_bottom = 1100
	_rb.add_child(_camera)

	_hud = Hud.new()
	add_child(_hud)

	_panel = TuningPanel.new()
	_panel.restart_requested.connect(_restart)
	_panel.travel_requested.connect(_travel_to)
	_panel.level_requested.connect(load_level)
	add_child(_panel)

	load_level(Settings.level_index)

func load_level(index: int) -> void:
	_level.load_level(index)
	_hearts = Settings.max_hearts
	_celebrate = 0.0
	_flag = _level.flag()
	_camera.limit_right = int(_level.right_edge() + 60.0)
	# Kameran får följa med ända upp till banans tak, annars hamnar han utanför
	# bilden där banan är som högst. Marginalen är en halv skärm.
	_camera.limit_top = int(_level.top_edge() - 380.0)
	_build_crates()
	_rb.teleport_to(_level.spawn_point())
	_hud.update_state(_rb.state, _rb.aim_kind)
	_hud.show_hearts(_hearts, Settings.max_hearts if _level.has_enemies() else 0)
	_hud.show_chain(0)
	_hud.show_goal(false)

## Målet. Flaggan märker själv när han rör den; här firas det och banan börjar
## om, så att den som klarat den kan klara den igen med en gång.
##
## Firandet går i riktig tid: slow motion är en inställning, och den som spelar
## långsamt ska inte få ett längre firande än den som spelar fort.
## Kameran ska aldrig tappa honom.
##
## Utjämningen sluter avståndet i en fast takt, så släpet blir ungefär
## fart/utjämning. Med 4,0 betyder det 400 px släp i 1600 px/s — och halva
## bilden är bara 343 px på höjden. Mätt: skjuten rakt upp i 1600 px/s hamnade
## han **162 px ovanför bildens överkant**, alltså utanför bild.
##
## Farten kommer ur mekaniken och ska få göra det: hoppet läggs till den fart
## han redan har (DECISIONS 21), så en rullning plus ett par tryck bär honom
## långt över tusen. Det är inte farten som är felet, det är att kameran inte
## följer med.
##
## Åtstramningen måste styras av **släpet** och inte av farten. Första försöket
## skalade med farten, och det bet inte alls: ett skott rakt upp bromsas av
## gravitationen, så vid toppen är farten noll medan släpet är som störst — och
## då slappnade utjämningen av precis när den behövdes. Mätt gav det 143 px
## utanför bild i 1600 px/s, alltså lika illa som utan spärr.
##
## Nu växer takten med kvadraten på hur långt efter kameran ligger. Det ger ett
## tak som inte går att springa ifrån: släpet lägger sig där farten och
## inhämtningen väger jämnt, och den punkten flyttar sig bara som kubikroten ur
## farten. Med 170 px tillåtet släp betyder det 243 px i 2000 px/s och 278 px i
## 3000 — båda innanför halva bilden, som är 343 px på höjden. I gångfart är
## takten kvar på 4,0 och känns likadan som förut.
const CAMERA_EASE := 4.0
const CAMERA_GRIP := 30.0   ## tak, så att den inte blir knyckig vid bankanterna

func _follow_camera() -> void:
	# Kamerans övre gräns finns för att den inte ska driva upp i tom himmel när
	# han står på marken — inte för att gömma honom. Och han *kan* komma över
	# banans egen kant: ett skott rakt upp i 1800 px/s stiger 1157 px, alltså
	# 737 px över gränsen i Lekplatsen, och då hjälper ingen utjämning i världen.
	# Mätt utan det här: 407 px utanför bild, med ett släp på 750 px som ingen
	# inhämtning kunde stå för — det var gränsen som höll kvar kameran.
	if _level != null:
		_camera.limit_top = int(minf(_level.top_edge() - 380.0, _rb.global_position.y - 400.0))
	var lag: float = maxf(Settings.camera_lag, 20.0)
	var off: float = (_rb.global_position - _camera.get_screen_center_position()).length()
	var grip := CAMERA_EASE
	if off > lag:
		grip = minf(CAMERA_EASE * (off / lag) * (off / lag), CAMERA_GRIP)
	_camera.position_smoothing_speed = grip

func _process(delta: float) -> void:
	_follow_camera()
	if _celebrate > 0.0:
		_celebrate -= WorldClock.unscaled(delta)
		if _celebrate <= 0.0:
			load_level(Settings.level_index)
		return
	if _flag == null or _flag.taken:
		return
	if _flag.touch(_rb.body_rect()):
		_hud.show_goal(true)
		_celebrate = 3.5
		if Settings.effects:
			_burst(_flag.global_position)

## Konfetti av spelets egna lådor, kastade ur flaggan. Ingen slump — samma mål
## ger samma smäll, precis som allt annat i spelet (docs/DESIGN.md 4a).
func _burst(at: Vector2) -> void:
	for i in 8:
		var piece := Crate.new()
		piece.box = Vector2(18, 18)
		piece.position = at + Vector2(0.0, -Flag.POLE)
		_crates.add_child(piece)
		var a := PI * (0.15 + 0.7 * float(i) / 7.0)
		piece.apply_impulse(Vector2(cos(a), -sin(a)) * 300.0)

func _build_crates() -> void:
	for child in _crates.get_children():
		child.queue_free()
	for entry: Dictionary in _level.crate_layout():
		var crate := Crate.new()
		crate.box = entry["size"]
		crate.position = entry["pos"]
		_crates.add_child(crate)

func _on_state_changed(state: RoboBall.State) -> void:
	_hud.update_state(state, _rb.aim_kind)

## Ett hjärta per träff, och när de är slut börjar banan om från början — med
## alla fiender tillbaka. Att förlora är alltså att få börja om, inte att
## förlora något man byggt upp (docs/DESIGN.md princip 4).
func _on_hurt() -> void:
	_hearts -= 1
	_hud.show_hearts(_hearts, Settings.max_hearts)
	if _hearts <= 0:
		load_level(Settings.level_index)

func _on_chained(kills: int) -> void:
	_hud.show_chain(kills)

func _restart() -> void:
	_build_crates()
	_rb.respawn()

func _travel_to(position: Vector2) -> void:
	_rb.teleport_to(position)

## Funktionstangenter är undantagna från spelets signal (se core/input_signal.gd)
## eftersom inget hjälpmedel skickar dem. De finns för att slippa leta i panelen
## mitt i ett speltest.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1:
			_panel.toggle()
		KEY_F2:
			Settings.control_variant = (Settings.control_variant + 1) % 3
			Settings.notify_changed()
			Settings.save_settings()
			_hud.update_state(_rb.state, _rb.aim_kind)
		KEY_F3:
			Settings.level_index = (Settings.level_index + 1) % Levels.names().size()
			Settings.save_settings()
			load_level(Settings.level_index)
		KEY_F8:
			_restart()
		_:
			return
	get_viewport().set_input_as_handled()
