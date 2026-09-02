extends CharacterBody2D
class_name RoboBall
## RB — en robotboll med ett öga och strutsben.
##
## Tre lägen och en enda signal. Se docs/DESIGN.md, avsnitt "Kärnloop".
##
## FAS 0 använder CharacterBody2D med Godots vanliga golvhantering, vilket klarar
## gång, lutningar och kanter. Den handskrivna markkontrollern som behövs för
## loopar och korkskruvar (Sonic-modellen: fart lagrad längs ytans tangent) hör
## till fas 1 — se docs/TECH.md, avsnitt "Fysikarkitektur".

signal state_changed(state: State)

enum State { WALK, AIM, AIR }

const RADIUS := 22.0
const WALK_SPEED := 130.0
const AIM_MIN_DEG := 20.0
const AIM_MAX_DEG := 160.0
const AUTO_AIM_DELAY := 0.7   ## hur länge pilen visas innan spelet hoppar åt en
const SIM_STEP := 1.0 / 45.0
const SIM_STEPS := 70

var state: State = State.WALK
var facing := 1
var aim_deg := 90.0

var _sweep_t := 0.0
var _aim_elapsed := 0.0
var _auto_angle := 90.0
var _leg_phase := 0.0
var _start_position := Vector2.ZERO
var _ledge_ray: RayCast2D

## Noderna byggs i kod i stället för i en scenfil — RB har få delar, och det
## håller allt som beskriver honom i en enda läsbar fil.
func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)

	_ledge_ray = RayCast2D.new()
	_ledge_ray.target_position = Vector2(RADIUS + 8.0, RADIUS + 22.0)
	add_child(_ledge_ray)

	_start_position = global_position
	floor_snap_length = 12.0
	floor_max_angle = deg_to_rad(50.0)
	InputSignal.pressed.connect(_on_signal_pressed)
	InputSignal.released.connect(_on_signal_released)

func _physics_process(delta: float) -> void:
	match state:
		State.WALK:
			_process_walk(delta)
		State.AIM:
			_process_aim(delta)
		State.AIR:
			_process_air(delta)
	queue_redraw()

# ---------------------------------------------------------------- lägen

func _process_walk(delta: float) -> void:
	_leg_phase += delta * 9.0
	velocity.x = facing * WALK_SPEED * Settings.walk_speed
	velocity.y += Settings.rb_gravity * delta
	move_and_slide()

	if is_on_wall():
		_turn_around()
	elif Settings.ledge_guard and is_on_floor() and not _ground_ahead():
		_turn_around()

	if not is_on_floor() and velocity.y > 0.0:
		# Ramlade över en kant med kantskyddet avstängt — fritt fall, inte ett hopp.
		_set_state(State.AIR)

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
		_set_state(State.WALK)

func _process_air(delta: float) -> void:
	velocity.y += Settings.rb_gravity * delta
	move_and_slide()
	_push_things()

	if is_on_floor():
		if not is_zero_approx(velocity.x):
			facing = 1 if velocity.x >= 0.0 else -1
		velocity = Vector2.ZERO
		_set_state(State.WALK)
	elif is_on_wall():
		velocity.x = -velocity.x * Settings.wall_bounce

	if global_position.y > _start_position.y + 1400.0:
		respawn()

# ---------------------------------------------------------------- signalen

func _on_signal_pressed() -> void:
	match state:
		State.WALK:
			_begin_aim()
		State.AIM:
			if Settings.control_variant == Settings.ControlVariant.CLASSIC:
				_launch()
		State.AIR:
			pass

func _on_signal_released() -> void:
	if state == State.AIM and Settings.control_variant == Settings.ControlVariant.HOLD_RELEASE:
		_launch()

func _begin_aim() -> void:
	_aim_elapsed = 0.0
	_sweep_t = 0.0
	if Settings.control_variant == Settings.ControlVariant.AUTO_AIM:
		_auto_angle = _pick_best_angle()
		aim_deg = _auto_angle
	_set_state(State.AIM)

func _launch() -> void:
	var a := deg_to_rad(aim_deg)
	velocity = Vector2(cos(a), -sin(a)) * Settings.jump_power
	facing = 1 if velocity.x >= 0.0 else -1
	_set_state(State.AIR)

func _set_state(next: State) -> void:
	if state == next:
		return
	state = next
	WorldClock.set_slowmo(state == State.AIM)
	state_changed.emit(state)

func set_start_position(pos: Vector2) -> void:
	_start_position = pos

func teleport_to(pos: Vector2) -> void:
	_start_position = pos
	respawn()

func respawn() -> void:
	global_position = _start_position
	velocity = Vector2.ZERO
	facing = 1
	_set_state(State.WALK)

# ---------------------------------------------------------------- hjälpare

func _turn_around() -> void:
	facing = -facing
	velocity.x = 0.0

func _ground_ahead() -> bool:
	_ledge_ray.target_position = Vector2(facing * (RADIUS + 8.0), RADIUS + 22.0)
	_ledge_ray.force_raycast_update()
	return _ledge_ray.is_colliding()

func _push_things() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider()
		if body is RigidBody2D:
			var impulse := velocity * Settings.push_force
			body.apply_impulse(impulse, c.get_position() - body.global_position)
			if body.has_method("take_impact"):
				body.take_impact(velocity.length())

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
	_draw_body()

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

func _draw_body() -> void:
	var crouch := state == State.AIM
	var body_y := -RADIUS + (4.0 if crouch else 0.0)
	var squash := 0.86 if crouch else 1.0

	# strutsben
	for s in [-1.0, 1.0]:
		var swing := sin(_leg_phase + (0.0 if s > 0.0 else PI)) * (6.0 if state == State.WALK else 0.0)
		var hip := Vector2(s * 6.0, body_y + RADIUS * 0.5)
		var knee := Vector2(s * 6.0 + swing * 0.4, body_y + RADIUS * (0.6 if crouch else 1.1))
		var foot := Vector2(s * 6.0 + swing, RADIUS * (0.35 if crouch else 0.95))
		draw_polyline(PackedVector2Array([hip, knee, foot]), Palette.INK, 3.0, true)

	draw_set_transform(Vector2(0.0, body_y), 0.0, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, RADIUS, Palette.SHELL)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Palette.INK, 3.0, true)
	var eye := Vector2(facing * 6.0, -2.0)
	draw_circle(eye, 7.5, Palette.SHELL)
	draw_arc(eye, 7.5, 0.0, TAU, 20, Palette.INK, 2.5, true)
	draw_circle(eye + Vector2(facing * 2.5, 0.0), 3.4, Palette.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
