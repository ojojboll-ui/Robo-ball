extends CharacterBody2D
class_name RoboBall
## RB — en robotboll med ett öga och strutsben.
##
## Markkontrollern lagrar farten **längs underlaget**, inte som x och y. Det är
## Sonic-modellen, och den är skälet till att ramper känns som ramper: en boll i
## en sluttning accelererar av gravitationens komponent längs ytan, inte av att
## någon har skrivit "öka farten här". Se docs/DESIGN.md avsnitt 4a — fysiken är
## innehållet, så den ska härledas och inte fejkas.
##
## Fyra lägen:
##   WALK  benen ute, han driver sig själv mot sin gångfart
##   ROLL  benen indragna, ingen drivning — bara lutning och rullmotstånd
##   AIM   fryst, pilen svepar, världen i slow motion
##   AIR   ren ballistik
##
## Övergången WALK → ROLL är den synliga versionen av en regel som annars är
## osynlig: blir backen brantare än benen klarar drar han in dem och blir en
## boll. Spelaren behöver ingen text för att förstå varför.

signal state_changed(state: State)

enum State { WALK, ROLL, AIM, AIR }

const RADIUS := 22.0            ## bollens radie, och kollisionscirkeln när han rullar
## Med benen ute är han en boll på ben, och kollisionskroppen ska säga samma sak:
## en kapsel som når från bollens topp ner till fötterna. När benen dras in
## *krymper* kapseln i stället för att bytas ut — en kapsel vars höjd är två
## radier är per definition en cirkel. Därför blir indragningen en mjuk rörelse
## över några bildrutor i stället för ett hack mellan två former, och benen viker
## ihop sig av sig själva när höften sjunker: fötterna står kvar på marken.
const CAPSULE_HEIGHT := 70.0
const STAND_HALF := CAPSULE_HEIGHT * 0.5
const BODY_LIFT := STAND_HALF - RADIUS   ## bollens mitt över kollisionsmitten
const WALK_SPEED := 130.0
const AIM_MIN_DEG := 20.0
const AIM_MAX_DEG := 160.0
const AUTO_AIM_DELAY := 0.7    ## hur länge pilen visas innan spelet hoppar åt en
const SAFETY_MARGIN := 2.0     ## slack i förflyttningstaket, se _move()
const STAND_UP_MARGIN := 6.0   ## hysteres, annars fladdrar han mellan lägena
## Hur hårt han hålls mot underlaget ligger i Settings.ground_stick. Farten är
## helt tangentiell, och uppför en backe pekar tangenten bort från marken — utan
## den kraften lättar han från ytan var trettonde bildruta och spelet fladdrar
## mellan "går" och "i luften". Den avgör också hur väl han följer med över ett
## krön: räcker den inte, lyfter han, precis som han ska.
const SIM_STEP := 1.0 / 45.0
const SIM_STEPS := 70

var state: State = State.WALK
var facing := 1
var aim_deg := 90.0
## Fart längs underlagets tangent. Positiv = åt höger längs ytan.
var ground_speed := 0.0
var ground_normal := Vector2.UP
var spin := 0.0                ## bollens rotation, härledd ur farten

var _sweep_t := 0.0
var _aim_elapsed := 0.0
var _air_jumps_used := 0
var _aim_from_air := false
var _airborne_frames := 0
var _legs := Legs.new()
var _shape: CollisionShape2D
var _capsule := CapsuleShape2D.new()
## 1.0 = benen ute, 0.0 = helt indragna. Allt annat följer av den här siffran.
var _stance := 1.0
## Underlagets normal, utjämnad. Rå normal hoppar till vid varje skarv mellan
## kollisionspolygonens delar, och det syntes som ryck i kroppens lutning.
var _smooth_normal := Vector2.UP
var _start_position := Vector2.ZERO
var _ledge_ray: RayCast2D

## Noderna byggs i kod i stället för i en scenfil — RB har få delar, och det
## håller allt som beskriver honom i en enda läsbar fil.
func _ready() -> void:
	_capsule.radius = RADIUS
	_capsule.height = CAPSULE_HEIGHT
	_shape = CollisionShape2D.new()
	_shape.shape = _capsule
	add_child(_shape)

	_ledge_ray = RayCast2D.new()
	add_child(_ledge_ray)

	_legs.body_lift = BODY_LIFT
	_start_position = global_position
	floor_snap_length = 20.0
	_legs.reset(self, Vector2.UP)
	InputSignal.pressed.connect(_on_signal_pressed)
	InputSignal.released.connect(_on_signal_released)

func _physics_process(delta: float) -> void:
	# Vad som räknas som golv avgörs av bollformen, inte av benen. Brantare än
	# så tappar han fästet helt och faller.
	floor_max_angle = deg_to_rad(Settings.roll_max_slope)
	_update_stance_shape(delta)
	match state:
		State.WALK, State.ROLL:
			_process_ground(delta)
		State.AIM:
			_process_aim(delta)
		State.AIR:
			_process_air(delta)
	_update_legs(delta)
	queue_redraw()

func _update_legs(delta: float) -> void:
	var grounded := state == State.WALK or state == State.AIM
	_smooth_normal = _smooth_normal.lerp(ground_normal, minf(1.0, delta * 14.0)).normalized()
	if _stance < 0.08:
		# Helt indragna — då finns inget att simulera, och kroppen sitter åter
		# fast i bollen eftersom det *är* bollen som rullar.
		_legs.body_point = global_position
		return
	# Under indragningen simuleras benen fortfarande. Höften sjunker med
	# kapseln, fötterna står kvar, och vikningen kommer ur geometrin.
	_legs.update(self, _smooth_normal, ground_speed, grounded or state == State.ROLL, delta)

# ---------------------------------------------------------------- lägen

func _process_ground(delta: float) -> void:
	var t := tangent()
	# Gravitationens komponent längs ytan, i full styrka. På plan mark är den
	# noll, i en sluttning är den allt.
	ground_speed += Settings.rb_gravity * t.y * delta

	if state == State.WALK:
		var target := facing * WALK_SPEED * Settings.walk_speed
		ground_speed = move_toward(ground_speed, target, Settings.walk_accel * delta)
	else:
		ground_speed = move_toward(ground_speed, 0.0, Settings.roll_friction * delta)

	spin += ground_speed / RADIUS * delta
	velocity = t * ground_speed - ground_normal * Settings.ground_stick
	_move(delta)
	_push_things(0.5)

	if is_on_wall():
		_hit_wall()

	if not is_on_floor():
		# Några bildrutors nåd. Kryper han uppför en brant lutning tappar han
		# annars marken en enstaka bildruta i taget och fladdrar mellan lägena.
		_airborne_frames += 1
		if _airborne_frames > 3:
			velocity = tangent() * ground_speed
			_set_state(State.AIR)
		return
	_airborne_frames = 0

	ground_normal = get_floor_normal()
	if not is_zero_approx(ground_speed):
		facing = 1 if ground_speed > 0.0 else -1
	if Settings.ledge_guard and state == State.WALK and not _ground_ahead():
		_turn_around()
	_update_stance()

func _process_aim(delta: float) -> void:
	velocity = Vector2.ZERO
	# Pilen och tålamodet lever i riktig tid — slow motion får aldrig göra
	# siktandet självt långsammare, den ger bara spelaren mer tid.
	var real := WorldClock.unscaled(delta)
	_aim_elapsed += real

	if Settings.control_variant == Settings.ControlVariant.AUTO_AIM:
		aim_deg = _auto_angle
		if _aim_elapsed >= AUTO_AIM_DELAY:
			_launch()
		return

	_sweep_t += real * Settings.aim_sweep_speed * 1.6
	# Bågen startar bakom RB och svepar fram mot den håll han går åt. Det ger
	# spelaren ett helt svep på sig att förbereda det hopp hen troligen vill
	# göra, i stället för att missa framåtvinkeln direkt och få vänta ett varv.
	# Cosinus i stället för sinus gör dessutom att pilen börjar stilla vid
	# ytterläget och accelererar mjukt.
	var t := 0.5 + 0.5 * cos(_sweep_t) * float(facing)
	aim_deg = lerpf(AIM_MIN_DEG, AIM_MAX_DEG, t)
	if Settings.aim_steps > 1:
		# Diskreta vinklar: lättare att träffa rätt, och möjligt att beskriva
		# i ord för någon som behöver hjälp att välja.
		var span := AIM_MAX_DEG - AIM_MIN_DEG
		var step := span / float(Settings.aim_steps - 1)
		aim_deg = AIM_MIN_DEG + roundf((aim_deg - AIM_MIN_DEG) / step) * step

	if Settings.aim_timeout > 0.0 and _aim_elapsed > Settings.aim_timeout:
		_set_state(State.AIR if _aim_from_air else _stance_for_slope())

func _process_air(delta: float) -> void:
	velocity.y += Settings.rb_gravity * delta
	spin += velocity.x / RADIUS * delta * 0.5
	_move(delta)
	_push_things(1.0)

	if is_on_floor():
		_land()
	elif is_on_wall():
		velocity.x = -velocity.x * Settings.wall_bounce

	if global_position.y > _start_position.y + 1400.0:
		respawn()

## Landningen bevarar rörelsemängden: farten projiceras på underlagets tangent
## i stället för att nollställas. Det är därför ett hopp ner i en sluttning
## fortsätter nedför i stället för att stanna som en säck.
func _land() -> void:
	_airborne_frames = 0
	ground_normal = get_floor_normal()
	# Fötterna har hängt under kroppen under fallet. Sätt ner dem på underlaget
	# vid landningen — annars står de kvar i luften och benen ser lösa ut.
	_legs.reset(self, ground_normal)
	ground_speed = velocity.dot(tangent())
	if not is_zero_approx(ground_speed):
		facing = 1 if ground_speed > 0.0 else -1
	velocity = Vector2.ZERO
	_air_jumps_used = 0
	_set_state(_stance_for_slope())

# ---------------------------------------------------------------- hållning

func tangent() -> Vector2:
	return Vector2(-ground_normal.y, ground_normal.x)

## Underlagets lutning i grader, oavsett åt vilket håll det lutar.
func slope_degrees() -> float:
	return absf(rad_to_deg(ground_normal.angle_to(Vector2.UP)))

func _stance_for_slope() -> State:
	if Settings.auto_roll and slope_degrees() > Settings.leg_max_slope:
		return State.ROLL
	return State.WALK

## Benen ut eller in. Hysteresen finns för att han annars skulle fladdra mellan
## lägena på en lutning som ligger precis på gränsen.
func _update_stance() -> void:
	if not Settings.auto_roll:
		if state == State.ROLL:
			_set_state(State.WALK)
		return
	var slope := slope_degrees()
	if state == State.WALK and slope > Settings.leg_max_slope:
		_set_state(State.ROLL)
	elif state == State.ROLL and slope < Settings.leg_max_slope - STAND_UP_MARGIN \
			and absf(ground_speed) < WALK_SPEED * Settings.walk_speed * 1.3:
		_set_state(State.WALK)

func _hit_wall() -> void:
	if state == State.ROLL:
		ground_speed = -ground_speed * Settings.wall_bounce
	else:
		facing = -facing
		ground_speed = 0.0

# ---------------------------------------------------------------- signalen

func _on_signal_pressed() -> void:
	match state:
		State.WALK, State.ROLL:
			_begin_aim()
		State.AIM:
			if Settings.control_variant == Settings.ControlVariant.CLASSIC:
				_launch()
		State.AIR:
			# Dubbelhopp: samma två tryck som på marken, mitt i luften. RB
			# stannar upp medan pilen svepar, så förmågan lägger till räckvidd
			# utan att lägga till en enda ny inmatning — kravet varje förmåga
			# i det här spelet måste klara (docs/DESIGN.md avsnitt 5).
			if _air_jumps_used < Settings.air_jumps:
				_begin_aim()

func _on_signal_released() -> void:
	if state == State.AIM and Settings.control_variant == Settings.ControlVariant.HOLD_RELEASE:
		_launch()

func _begin_aim() -> void:
	_aim_elapsed = 0.0
	_sweep_t = 0.0
	_aim_from_air = state == State.AIR
	if Settings.control_variant == Settings.ControlVariant.AUTO_AIM:
		_auto_angle = _pick_best_angle()
		aim_deg = _auto_angle
	_set_state(State.AIM)

var _auto_angle := 90.0

func _launch() -> void:
	if _aim_from_air:
		_air_jumps_used += 1
	var a := deg_to_rad(aim_deg)
	velocity = Vector2(cos(a), -sin(a)) * Settings.jump_power
	ground_speed = 0.0
	facing = 1 if velocity.x >= 0.0 else -1
	_set_state(State.AIR)

func _set_state(next: State) -> void:
	if state == next:
		return
	# Reser han sig ur en rullning har benen inga giltiga fotplaceringar kvar —
	# utan en omstart skulle de kliva från där de stod innan han rullade.
	if state == State.ROLL and next != State.ROLL:
		_legs.reset(self, _smooth_normal)
	state = next
	WorldClock.set_slowmo(state == State.AIM)
	state_changed.emit(state)

## Vill han vara boll just nu? Rullande alltid — men också på väg ner mot en yta
## som är för brant för benen. Landar han stående på en ramp tar han emot med
## fötterna och tappar farten innan rullningen hinner börja; ser han backen
## komma hinner han vika ihop sig och anländer som den boll backen kräver.
func _wants_ball() -> bool:
	if state == State.ROLL:
		return true
	if state != State.AIR or not Settings.auto_roll or not Settings.tuck_before_landing:
		return false
	return _incoming_slope() > Settings.leg_max_slope

## Lutningen på det han är på väg att träffa, eller -1 om han inte ser något.
func _incoming_slope() -> float:
	if velocity.length() < 1.0:
		return -1.0
	var ahead := velocity * Settings.tuck_lookahead
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + ahead, collision_mask, [get_rid()])
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return -1.0
	return absf(rad_to_deg((hit["normal"] as Vector2).angle_to(Vector2.UP)))

## Kapselns höjd följer hållningen: full höjd med benen ute, två radier — alltså
## en cirkel — när de är indragna. Fötterna står still medan höften sjunker, så
## benen viker ihop sig av sig själva. Kroppen flyttas med halva höjdändringen
## så att kapselns undersida står kvar på marken hela vägen.
func _update_stance_shape(delta: float) -> void:
	var target := 0.0 if _wants_ball() else 1.0
	_stance = move_toward(_stance, target, Settings.tuck_speed * delta)
	var height := lerpf(RADIUS * 2.0, CAPSULE_HEIGHT, _stance)
	var change := height - _capsule.height
	if absf(change) > 0.001:
		_capsule.height = height
		var up := ground_normal if ground_normal.length() > 0.1 else Vector2.UP
		global_position += up * change * 0.5
	_legs.body_lift = height * 0.5 - RADIUS
	_legs.body_height = height - RADIUS

func set_start_position(pos: Vector2) -> void:
	_start_position = pos

func teleport_to(pos: Vector2) -> void:
	_start_position = pos
	respawn()

func respawn() -> void:
	_stance = 1.0
	_capsule.height = CAPSULE_HEIGHT
	global_position = _start_position
	velocity = Vector2.ZERO
	ground_speed = 0.0
	ground_normal = Vector2.UP
	_smooth_normal = Vector2.UP
	facing = 1
	_air_jumps_used = 0
	_legs.reset(self, Vector2.UP)
	_set_state(State.WALK)

# ---------------------------------------------------------------- hjälpare

## move_and_slide med tak på hur långt en bildruta får flytta RB.
##
## Fysikmotorn löser överlapp genom att trycka ut kroppen ur det den fastnat i,
## och sitter han djupt inne i en låda blir den knuffen enorm — RB skjuts rakt
## upp ur bild. Ett sådant hopp går aldrig att förklara med hans egen fart, så
## vi mäter förflyttningen mot vad farten tillåter och kapar överskottet.
func _move(delta: float) -> void:
	var before := global_position
	var allowed := velocity.length() * delta + SAFETY_MARGIN
	move_and_slide()
	var moved := global_position - before
	if moved.length() > allowed:
		global_position = before + moved.normalized() * allowed

func _turn_around() -> void:
	facing = -facing
	ground_speed = 0.0

func _ground_ahead() -> bool:
	var lean := ground_normal.angle() + PI * 0.5
	_ledge_ray.target_position = Vector2(facing * (RADIUS + 8.0), _capsule.height * 0.5 + 22.0).rotated(lean)
	_ledge_ray.force_raycast_update()
	return _ledge_ray.is_colliding()

func _push_things(strength: float) -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider()
		if not (body is RigidBody2D):
			continue
		if body.has_method("take_impact"):
			body.take_impact(velocity.length())
		# Knuffa aldrig något som ligger under oss. Gör man det trycks lådan ner
		# i marken, marken trycker tillbaka, och fysikmotorn löser överlappet
		# genom att kasta ut RB uppåt — bildruta efter bildruta. Att stå på
		# något är inte att knuffa det.
		if c.get_normal().y < -0.5:
			continue
		var impulse := velocity * Settings.push_force * strength
		body.apply_impulse(impulse, c.get_position() - body.global_position)

## Simulerar hoppbanan mot den riktiga kollisionsvärlden. Eftersom lufttiden är
## ren ballistik är resultatet exakt — det är därför förhandsbanan går att visa
## och därför auto-siktet kan välja åt spelaren.
func simulate(angle_deg: float, steps: int = SIM_STEPS) -> Dictionary:
	var a := deg_to_rad(angle_deg)
	var pos := global_position
	var vel := Vector2(cos(a), -sin(a)) * Settings.jump_power
	var points := PackedVector2Array()
	var space := get_world_2d().direct_space_state
	for i in steps:
		vel.y += Settings.rb_gravity * SIM_STEP
		var next := pos + vel * SIM_STEP
		var query := PhysicsRayQueryParameters2D.create(pos, next, collision_mask, [get_rid()])
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			points.append(hit.position)
			return {"points": points, "landed": true, "end": hit.position}
		points.append(next)
		pos = next
	return {"points": points, "landed": false, "end": pos}

## Auto-sikte: spelet väljer vinkeln. Det är inte fusk — det flyttar
## svårighetsgraden från precision till timing, och är för en del spelare
## skillnaden mellan att kunna spela och att titta på.
func _pick_best_angle() -> float:
	var best := 90.0
	var best_score := -INF
	var angle := AIM_MIN_DEG
	while angle <= AIM_MAX_DEG:
		var sim := simulate(angle, 55)
		if sim["landed"]:
			var end: Vector2 = sim["end"]
			var forward := facing * (end.x - global_position.x)
			var upward := global_position.y - end.y
			var score := forward + upward * 1.5
			if forward > 24.0 and score > best_score:
				best_score = score
				best = angle
		angle += 6.0
	return best

# ---------------------------------------------------------------- ritning

func _draw() -> void:
	if state == State.AIM:
		_draw_aim()
	if _stance < 0.08:
		_draw_rolling()
	else:
		_draw_standing()

func _draw_aim() -> void:
	var a := deg_to_rad(aim_deg)
	var dir := Vector2(cos(a), -sin(a))
	var origin := Vector2(0.0, -RADIUS - 16.0)
	var tip := origin + dir * 46.0
	draw_line(origin, tip, Palette.PINK, 5.0, true)
	var back := tip - dir * 12.0
	var side := dir.orthogonal() * 8.0
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Palette.PINK)

	if Settings.trajectory_preview:
		var sim := simulate(aim_deg)
		var pts: PackedVector2Array = sim["points"]
		for i in pts.size():
			if i % 3 != 0:
				continue
			var fade := 1.0 - float(i) / float(maxi(pts.size(), 1))
			draw_circle(to_local(pts[i]), 3.0, Color(Palette.PINK, 0.15 + 0.55 * fade))

## Indragna ben: kroppen sjunker ner ett helt radieavstånd och blir den boll han
## var innan han hittade benen. Rotationen är härledd ur farten, inte animerad —
## en boll som rullar dubbelt så fort snurrar dubbelt så fort.
func _draw_rolling() -> void:
	draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
	draw_circle(Vector2.ZERO, RADIUS, Palette.SHELL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Palette.INK, 3.0, true)
	var eye := Vector2(RADIUS * 0.34, -RADIUS * 0.3)
	draw_circle(eye, 7.5, Palette.SHELL)
	draw_arc(eye, 7.5, 0.0, TAU, 20, Palette.INK, 2.5, true)
	draw_circle(eye + Vector2(2.2, 0.0), 3.4, Palette.INK)
	# benstumparna sticker ut, indragna mot skalet
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 9.0, 12.0), Vector2(s * 4.0, 18.0), Palette.INK, 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_standing() -> void:
	var normal := _smooth_normal
	var crouch := state == State.AIM
	var squash := 0.86 if crouch else 1.0
	var body := to_local(_legs.body_point)
	if crouch:
		# På huk: kroppen sjunker ner mot fötterna, benen viker ihop sig.
		body += normal * -8.0

	_legs.draw_into(self, normal, facing, Palette.INK)

	var lean := normal.angle() + PI * 0.5
	draw_set_transform(body, lean, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, RADIUS, Palette.SHELL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Palette.INK, 3.0, true)
	var eye := Vector2(facing * 6.0, -2.0)
	draw_circle(eye, 7.5, Palette.SHELL)
	draw_arc(eye, 7.5, 0.0, TAU, 20, Palette.INK, 2.5, true)
	draw_circle(eye + Vector2(facing * 2.5, 0.0), 3.4, Palette.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
