extends SceneTree

## Hostile Critic leftover-0 hunts. Not product. Not official verify.


func _initialize() -> void:
	call_deferred("_boot")


func _boot() -> void:
	seed(1)
	InputActions.install()
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var app: App = packed.instantiate() as App
	app.test_driven = true
	root.add_child(app)
	print("HH_HUNT start leftover-0")
	_hunt_hash_payload()
	await _hunt_oneway(app)
	await _hunt_police_liplip(app)
	await _hunt_jump_height(app)
	await _hunt_camera_follow(app)
	await _hunt_official_trace_y(app)
	print("HH_HUNT done")
	if is_instance_valid(app):
		app.shutdown()
		app.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _apply(session: GameSession, held: PackedStringArray, ticks: int, move_x: float) -> void:
	var n: int = 0
	while n < ticks:
		var frames: Array = []
		var i: int = 0
		while i < session.fighters.size():
			var raw: Dictionary = InputActions.empty_frame(session.clock.tick, i)
			if i == 0:
				raw["held"] = Array(held)
				raw["move_x"] = move_x
				if n == 0 and not held.is_empty():
					raw["pressed"] = Array(held)
			frames.append(InputFrame.from_dict(raw))
			i += 1
		session.apply_frames(frames)
		n += 1


func _hunt_hash_payload() -> void:
	print("HH_HUNT HASH2 keys-from-source: snapshot fighter row includes x AND y")
	print("HH_HUNT HASH2 collision_in_hash=false on_floor_not_hashed=true")


func _hunt_oneway(app: App) -> void:
	app.start_fight("vs2", "hazardous", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var p1: Fighter = session.player1()
	_apply(session, PackedStringArray(), 20, 0.0)
	var y_stand: float = p1.global_position.y
	var x_stand: float = p1.global_position.x
	var on_floor0: bool = p1.is_on_floor()
	print("HH_HUNT ONEWAY stand x=%s y=%s floor=%s dead=%s" % [
		str(x_stand), str(y_stand), str(on_floor0), str(p1.dead)
	])
	# Drop-through: hold crouch on one-way.
	_apply(session, PackedStringArray(["crouch"]), 24, 0.0)
	print("HH_HUNT DROP crouch y0=%s y1=%s crouched=%s floor=%s dead=%s" % [
		str(y_stand), str(p1.global_position.y), str(p1.crouched), str(p1.is_on_floor()), str(p1.dead)
	])
	if p1.crouched and p1.is_on_floor() and absf(p1.global_position.y - y_stand) < 6.0:
		print("HH_HUNT DROP verdict=fake_or_unshipped (crouch stays on one-way)")
	elif p1.dead or p1.global_position.y > y_stand + 20.0:
		print("HH_HUNT DROP verdict=fell")
	else:
		print("HH_HUNT DROP verdict=unclear")
	# From below: place under a one-way pipe (row 6 tiles y=96..112), jump up.
	app.start_fight("vs2", "hazardous", 0)
	await SimReplay.sync_physics(app)
	session = app.session
	p1 = session.player1()
	p1.global_position = Vector2(48.0, 130.0)
	p1.velocity = Vector2.ZERO
	_apply(session, PackedStringArray(), 8, 0.0)
	var y_below: float = p1.global_position.y
	print("HH_HUNT BELOW place x=%s y=%s floor=%s" % [
		str(p1.global_position.x), str(y_below), str(p1.is_on_floor())
	])
	var min_y: float = y_below
	var blocked: bool = false
	var passed: bool = false
	var t: int = 0
	while t < 40:
		_apply(session, PackedStringArray(["jump"]), 1, 0.0)
		if p1.global_position.y < min_y:
			min_y = p1.global_position.y
		# Row-6 one-way occupies y 96..112. Passing from below means min_y < 96.
		if p1.global_position.y <= 96.0:
			passed = true
		if p1.velocity.y >= 0.0 and t > 4 and p1.global_position.y > 100.0 and p1.global_position.y < 120.0:
			blocked = true
		t += 1
	print("HH_HUNT BELOW min_y=%s end_y=%s passed_above_96=%s blocked_hint=%s dead=%s" % [
		str(min_y), str(p1.global_position.y), str(passed), str(blocked), str(p1.dead)
	])
	# Storage: jump from floor toward overhead catwalk (row 2, y=32..48) — too high;
	# use row-6 catwalk y=96..112. Spawn floor is row 11 y=176.
	app.start_fight("vs2", "storage", 0)
	await SimReplay.sync_physics(app)
	session = app.session
	p1 = session.player1()
	p1.global_position = Vector2(200.0, 130.0)
	p1.velocity = Vector2.ZERO
	_apply(session, PackedStringArray(), 6, 0.0)
	var y_s: float = p1.global_position.y
	min_y = y_s
	t = 0
	while t < 36:
		_apply(session, PackedStringArray(["jump"]), 1, 0.0)
		if p1.global_position.y < min_y:
			min_y = p1.global_position.y
		t += 1
	print("HH_HUNT STORAGE_BELOW start_y=%s min_y=%s end_y=%s passed_row6=%s" % [
		str(y_s), str(min_y), str(p1.global_position.y), str(min_y < 96.0)
	])


func _hunt_police_liplip(app: App) -> void:
	# Official pit_fall is police walk-left. Record y while still over floor tiles.
	var path: String = "%s/pit_fall.json" % SimConstants.LOCO_TRACE_DIR
	var trace: Dictionary = SimTrace.load_path(path)
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var p1: Fighter = session.player1()
	var bundles: Array = SimTrace.expand_tick_bundles(trace)
	var floor_left_px: float = 6.0 * 16.0
	var floor_top: float = 12.0 * 16.0
	var lip_fall: int = 0
	var off_floor_over_solid: int = 0
	var i: int = 0
	print("HH_HUNT POLICE spawn x=%s y=%s floor=%s floor_left=%s" % [
		str(p1.global_position.x), str(p1.global_position.y), str(p1.is_on_floor()), str(floor_left_px)
	])
	while i < bundles.size():
		var typed: Array = SimTrace.to_input_frames(bundles[i] as Array)
		session.apply_frames(typed)
		var x: float = p1.global_position.x
		var y: float = p1.global_position.y
		var on_f: bool = p1.is_on_floor()
		if x >= floor_left_px - 2.0 and y > floor_top + 2.0 and not p1.dead:
			lip_fall += 1
			if i < 20 or lip_fall <= 4:
				print("HH_HUNT LIP tick=%d x=%s y=%s floor=%s dead=%s" % [
					i, str(x), str(y), str(on_f), str(p1.dead)
				])
		if x >= floor_left_px + 4.0 and not on_f and not p1.dead and y < floor_top + 8.0:
			off_floor_over_solid += 1
		if p1.dead:
			print("HH_HUNT POLICE die tick=%d x=%s y=%s cause=%s over_solid=%s" % [
				i, str(x), str(y), p1.death_cause, str(x >= floor_left_px)
			])
			break
		i += 1
	print("HH_HUNT POLICE lip_fall_frames=%d off_floor_over_solid=%d ticks=%d dead=%s cause=%s" % [
		lip_fall, off_floor_over_solid, i, str(p1.dead), p1.death_cause
	])
	# Walk-accel official trace: stay on floor, y should not sink into tiles.
	path = "%s/walk_accel_friction.json" % SimConstants.LOCO_TRACE_DIR
	trace = SimTrace.load_path(path)
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	session = app.session
	p1 = session.player1()
	bundles = SimTrace.expand_tick_bundles(trace)
	i = 0
	var min_y: float = p1.global_position.y
	var max_y: float = p1.global_position.y
	var sunk: int = 0
	while i < bundles.size():
		session.apply_frames(SimTrace.to_input_frames(bundles[i] as Array))
		var y2: float = p1.global_position.y
		if y2 < min_y:
			min_y = y2
		if y2 > max_y:
			max_y = y2
		if p1.global_position.x >= floor_left_px and y2 > floor_top + 4.0 and not p1.dead:
			sunk += 1
		i += 1
	print("HH_HUNT WALK y_min=%s y_max=%s sunk_frames=%d dead=%s x=%s" % [
		str(min_y), str(max_y), sunk, str(p1.dead), str(p1.global_position.x)
	])


func _hunt_jump_height(app: App) -> void:
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var p1: Fighter = session.player1()
	_apply(session, PackedStringArray(), 14, 0.0)
	var y0: float = p1.global_position.y
	var jv: float = p1.jump_vel
	var g: float = p1.gravity
	var expected: float = (jv * jv) / (2.0 * g)
	_apply(session, PackedStringArray(["jump"]), 20, 0.0)
	var n: int = 0
	var peak: float = p1.global_position.y
	while n < 40:
		if p1.global_position.y < peak:
			peak = p1.global_position.y
		_apply(session, PackedStringArray(), 1, 0.0)
		n += 1
	var rise: float = y0 - peak
	var eps: float = Locomotion.epsilon()
	print("HH_HUNT JUMP y0=%s peak=%s rise=%s ballistic=%s delta=%s eps=%s in_eps=%s" % [
		str(y0), str(peak), str(rise), str(expected), str(absf(rise - expected)), str(eps),
		str(absf(rise - expected) <= eps)
	])


func _hunt_camera_follow(app: App) -> void:
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var p1: Fighter = session.player1()
	var cam0: Vector2 = session.camera.position
	var p0: Vector2 = p1.global_position
	_apply(session, PackedStringArray(["right"]), 40, 1.0)
	session._fit_camera()
	var cam1: Vector2 = session.camera.position
	var p1p: Vector2 = p1.global_position
	print("HH_HUNT CAM p0=%s p1=%s dp=%s cam0=%s cam1=%s dcam=%s follow=%s" % [
		str(p0), str(p1p), str(p1p - p0), str(cam0), str(cam1), str(cam1 - cam0),
		str(cam1.distance_to(p1p) < 80.0)
	])


func _hunt_official_trace_y(app: App) -> void:
	var names: PackedStringArray = PackedStringArray([
		"walk_accel_friction", "crouch_shape", "pit_fall",
		"no_tunnel_solid", "no_tunnel_oneway", "variable_jump"
	])
	var i: int = 0
	while i < names.size():
		var path: String = "%s/%s.json" % [SimConstants.LOCO_TRACE_DIR, String(names[i])]
		var a: Dictionary = await SimReplay.play_path(app, path)
		var st: Dictionary = a.get("final_state", {}) as Dictionary
		var rows: Array = st.get("fighters", []) as Array
		var row: Dictionary = {}
		if not rows.is_empty():
			row = rows[0] as Dictionary
		print("HH_HUNT TRACE %s ok=%s hash=%s xq=%s yq=%s dead=%s cause=%s" % [
			String(names[i]),
			str(a.get("ok", false)),
			str(a.get("final_hash", "")).substr(0, 12),
			str(row.get("x", "")),
			str(row.get("y", "")),
			str(row.get("dead", "")),
			str(row.get("death_cause", ""))
		])
		i += 1
