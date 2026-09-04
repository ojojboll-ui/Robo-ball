extends Node
## Låt RB gå av sig själv i verkstaden en lång stund och leta efter lägen där
## han blir stående mot en vägg.

func _ready() -> void:
	var main: Node = load("res://main/main.tscn").instantiate()
	add_child(main)
	Settings.level_index = 2
	main.call("load_level", 2)
	await get_tree().process_frame
	var rb: RoboBall = main.get("_rb")
	rb.teleport_to(Vector2(4200, 580))
	var streak := 0
	var worst := 0
	var worst_at := Vector2.ZERO
	var worst_state := 0
	var last := rb.global_position
	for i in 3000:
		await get_tree().physics_frame
		var moved := rb.global_position.distance_to(last)
		last = rb.global_position
		if moved < 0.7 and rb.state == RoboBall.State.ROLL and absf(rb.ground_speed) > 40.0:
			streak += 1
			if streak > worst:
				worst = streak
				worst_at = rb.global_position
				worst_state = rb.state
		else:
			streak = 0
	print("längsta stund rullande utan att röra sig: %d frames (%.2f s) vid %s" % [
		worst, worst / 60.0, worst_at])
	print("slutläge: x=%.0f %s fart %.0f" % [rb.global_position.x, _name(rb.state), rb.ground_speed])
	get_tree().quit()

func _name(s: int) -> String:
	return ["GÅR", "RULLAR", "SIKTAR", "LUFT", "HÄNGER"][s] if s < 5 else str(s)
