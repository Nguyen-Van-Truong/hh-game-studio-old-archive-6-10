extends SceneTree

const STEP: float = 1.0 / 60.0


func _initialize() -> void:
	call_deferred("_boot")


func _boot() -> void:
	InputActions.install()
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var app: App = packed.instantiate() as App
	app.test_driven = true
	root.add_child(app)
	await _flush(8)
	await _probe_landings(app)
	await _probe_one_way(app)
	await _probe_drop_through(app)
	await _probe_police(app)
	await _probe_grenade_hold(app)
	await _probe_standing_gun_loot(app)
	await _probe_uzi_auto(app)
	_probe_title(app)
	if is_instance_valid(app):
		app.queue_free()
	quit(0)


func _flush(n: int) -> void:
	var i: int = 0
	while i < n:
		await physics_frame
		i += 1


func _idle(session: GameSession) -> Array[Dictionary]:
	var cmds: Array[Dictionary] = []
	var i: int = 0
	while i < session.fighters.size():
		cmds.append(InputActions.empty_cmd())
		i += 1
	return cmds


func _settle(session: GameSession, n: int) -> void:
	var i: int = 0
	while i < n:
		session.step_fixed(STEP, _idle(session))
		i += 1


func _start(app: App, mode: String, map_id: String) -> Fighter:
	app.start_fight(mode, map_id, 0)
	return app.session.player1()


func _first_eq(map_id: String) -> Vector2i:
	var rows: PackedStringArray = Maps.grid(map_id)
	var y: int = 0
	while y < rows.size():
		var row: String = String(rows[y])
		var x: int = 0
		while x < row.length():
			if row.substr(x, 1) == "=":
				return Vector2i(x, y)
			x += 1
		y += 1
	return Vector2i(-1, -1)


func _eq_over_floor(map_id: String) -> Vector2i:
	var rows: PackedStringArray = Maps.grid(map_id)
	var y: int = 0
	while y < rows.size():
		var row: String = String(rows[y])
		var x: int = 0
		while x < row.length():
			if row.substr(x, 1) == "=":
				var dy: int = 1
				while y + dy < rows.size():
					var under: String = String(rows[y + dy]).substr(x, 1)
					if under == "#" or under == "c" or under == "b":
						return Vector2i(x, y)
					if under == "=":
						break
					dy += 1
			x += 1
		y += 1
	return Vector2i(-1, -1)


func _probe_landings(app: App) -> void:
	var maps: PackedStringArray = PackedStringArray(["rooftops", "storage", "police", "hazardous"])
	var i: int = 0
	while i < maps.size():
		var mid: String = String(maps[i])
		var p1: Fighter = _start(app, "vs1", mid)
		var session: GameSession = app.session
		await _flush(6)
		var y_spawn: float = p1.global_position.y
		_settle(session, 20)
		print(
			"HH_PROBE LAND step20 map=%s spawn_y=%.1f y=%.1f on_floor=%s dead=%s cause=%s kill=%.1f"
			% [
				mid,
				y_spawn,
				p1.global_position.y,
				p1.is_on_floor(),
				p1.dead,
				p1.death_cause,
				Maps.kill_y(mid),
			]
		)
		p1 = _start(app, "vs1", mid)
		session = app.session
		await _flush(6)
		var n: int = 0
		while n < 20:
			await physics_frame
			n += 1
		print(
			"HH_PROBE LAND phys20 map=%s y=%.1f on_floor=%s dead=%s cause=%s"
			% [mid, p1.global_position.y, p1.is_on_floor(), p1.dead, p1.death_cause]
		)
		i += 1


func _probe_one_way(app: App) -> void:
	var p1: Fighter = _start(app, "vs1", "police")
	var session: GameSession = app.session
	await _flush(6)
	var cell: Vector2i = _eq_over_floor("police")
	var flag: bool = session.arena.platform_is_one_way()
	var cx: float = float(cell.x * Maps.TILE) + 8.0
	var top: float = float(cell.y * Maps.TILE)
	# Stand on the solid floor under this `=`, then jump.
	p1.global_position = Vector2(cx, float(11 * Maps.TILE))
	p1.velocity = Vector2.ZERO
	_settle(session, 12)
	await _flush(4)
	_settle(session, 4)
	var y0: float = p1.global_position.y
	var floor0: bool = p1.is_on_floor()
	var n: int = 0
	var min_y: float = y0
	var crossed: bool = false
	while n < 40:
		var cmds: Array[Dictionary] = _idle(session)
		cmds[0]["jump"] = true
		cmds[0]["jump_pressed"] = n == 0
		session.step_fixed(STEP, cmds)
		if p1.global_position.y < min_y:
			min_y = p1.global_position.y
		if p1.global_position.y < top - 2.0:
			crossed = true
		n += 1
	print(
		"HH_PROBE ONE_WAY flag=%s cell=%s floor0=%s y0=%.1f min_y=%.1f top=%.1f crossed=%s dead=%s"
		% [flag, cell, floor0, y0, min_y, top, crossed, p1.dead]
	)


func _probe_drop_through(app: App) -> void:
	var p1: Fighter = _start(app, "vs1", "police")
	var session: GameSession = app.session
	await _flush(6)
	var cell: Vector2i = _eq_over_floor("police")
	var cx: float = float(cell.x * Maps.TILE) + 8.0
	var top: float = float(cell.y * Maps.TILE)
	p1.global_position = Vector2(cx, top - 14.0)
	p1.velocity = Vector2.ZERO
	_settle(session, 16)
	await _flush(4)
	_settle(session, 8)
	var y0: float = p1.global_position.y
	var floor0: bool = p1.is_on_floor()
	var n: int = 0
	while n < 24:
		var cmds: Array[Dictionary] = _idle(session)
		cmds[0]["crouch"] = true
		session.step_fixed(STEP, cmds)
		n += 1
	print(
		"HH_PROBE STAND_ON_EQ y0=%.1f y1=%.1f top=%.1f floor0=%s floor1=%s dropped=%s"
		% [
			y0,
			p1.global_position.y,
			top,
			floor0,
			p1.is_on_floor(),
			p1.global_position.y > top + 10.0,
		]
	)


func _probe_police(app: App) -> void:
	var p1: Fighter = _start(app, "vs1", "police")
	var session: GameSession = app.session
	await _flush(8)
	_settle(session, 20)
	print(
		"HH_PROBE POLICE_SPAWN x=%.1f y=%.1f floor=%s dead=%s cause=%s"
		% [p1.global_position.x, p1.global_position.y, p1.is_on_floor(), p1.dead, p1.death_cause]
	)
	var extra: int = 0
	while extra < 20 and not p1.dead:
		session.step_fixed(STEP, _idle(session))
		extra += 1
	print(
		"HH_PROBE POLICE_IDLE40 extra=%d y=%.1f dead=%s cause=%s"
		% [extra, p1.global_position.y, p1.dead, p1.death_cause]
	)
	p1 = _start(app, "vs1", "police")
	session = app.session
	await _flush(8)
	_settle(session, 8)
	if p1.is_on_floor():
		var n: int = 0
		while n < 50 and not p1.dead:
			var cmds: Array[Dictionary] = _idle(session)
			cmds[0]["x"] = -1.0
			session.step_fixed(STEP, cmds)
			n += 1
		print(
			"HH_PROBE POLICE_WALK_LEFT frames=%d x=%.1f y=%.1f dead=%s cause=%s"
			% [n, p1.global_position.x, p1.global_position.y, p1.dead, p1.death_cause]
		)
	else:
		print("HH_PROBE POLICE_WALK_LEFT skipped_not_on_floor y=%.1f" % p1.global_position.y)
	p1 = _start(app, "vs1", "police")
	session = app.session
	await _flush(8)
	_settle(session, 8)
	var n2: int = 0
	var pit_inside: bool = false
	while n2 < 200 and not p1.dead:
		var walk: Array[Dictionary] = _idle(session)
		walk[0]["x"] = 1.0
		session.step_fixed(STEP, walk)
		if p1.death_cause == "pit":
			pit_inside = true
			break
		n2 += 1
	print(
		"HH_PROBE POLICE_WALK_RIGHT frames=%d x=%.1f y=%.1f floor=%s dead=%s cause=%s pit_inside=%s"
		% [
			n2,
			p1.global_position.x,
			p1.global_position.y,
			p1.is_on_floor(),
			p1.dead,
			p1.death_cause,
			pit_inside,
		]
	)
	var holes: PackedStringArray = PackedStringArray()
	var x: int = 22
	while x < 46:
		p1 = _start(app, "vs1", "police")
		session = app.session
		await _flush(6)
		p1.global_position = Vector2(float(x * Maps.TILE) + 8.0, float(11 * Maps.TILE) + 4.0)
		p1.velocity = Vector2.ZERO
		_settle(session, 18)
		await _flush(3)
		_settle(session, 6)
		if p1.dead or p1.death_cause == "pit" or not p1.is_on_floor():
			holes.append(
				"x=%d y=%.1f floor=%s cause=%s" % [x, p1.global_position.y, p1.is_on_floor(), p1.death_cause]
			)
		x += 2
	print("HH_PROBE POLICE_INTERIOR_HOLES n=%d %s" % [holes.size(), ",".join(holes)])


func _probe_grenade_hold(app: App) -> void:
	var p1: Fighter = _start(app, "vs1", "storage")
	var session: GameSession = app.session
	await _flush(8)
	_settle(session, 16)
	p1.grenades = 3
	p1.aim_dir = Vector2.RIGHT
	p1.facing = 1.0
	p1.dead = false
	var n: int = 0
	while n < 45 and session.outcome == "play":
		var held: Array[Dictionary] = _idle(session)
		held[0]["grenade_held"] = true
		session.step_fixed(STEP, held)
		n += 1
	var during: int = session.grenades.size()
	var nades_held: int = p1.grenades
	var rel: Array[Dictionary] = _idle(session)
	rel[0]["grenade_released"] = true
	session.step_fixed(STEP, rel)
	print(
		"HH_PROBE NADE_HOLD floor=%s outcome=%s dead=%s during_count=%d nades_during=%d after_count=%d nades_after=%d"
		% [
			p1.is_on_floor(),
			session.outcome,
			p1.dead,
			during,
			nades_held,
			session.grenades.size(),
			p1.grenades,
		]
	)


func _probe_standing_gun_loot(app: App) -> void:
	var p1: Fighter = _start(app, "vs1", "storage")
	var session: GameSession = app.session
	await _flush(8)
	_settle(session, 16)
	var drop: Pickup = session._add_pickup("uzi", p1.global_position + Vector2(0, 4), false)
	p1.melee_cd = 0.0
	p1.global_position = drop.global_position
	p1.gun_id = "pistol"
	p1.ammo = 12
	_settle(session, 8)
	var stand: Array[Dictionary] = _idle(session)
	stand[0]["melee"] = true
	session.step_fixed(STEP, stand)
	print(
		"HH_PROBE STAND_UZI floor=%s melee=%s gun=%s ammo=%d"
		% [p1.is_on_floor(), p1.melee_id, p1.gun_id, p1.ammo]
	)
	p1.melee_cd = 0.0
	p1.global_position = drop.global_position
	var grab: Array[Dictionary] = _idle(session)
	grab[0]["crouch"] = true
	grab[0]["melee"] = true
	session.step_fixed(STEP, grab)
	print(
		"HH_PROBE CROUCH_UZI floor=%s crouched=%s melee=%s gun=%s ammo=%d"
		% [p1.is_on_floor(), p1.crouched, p1.melee_id, p1.gun_id, p1.ammo]
	)


func _probe_uzi_auto(app: App) -> void:
	var p1: Fighter = _start(app, "vs1", "storage")
	var session: GameSession = app.session
	await _flush(8)
	_settle(session, 12)
	var foe: Fighter = session.fighters[1]
	p1.gun_id = "uzi"
	p1.weapon_id = "uzi"
	p1.ammo = 24
	p1.aim_dir = Vector2.RIGHT
	p1.facing = 1.0
	foe.global_position = p1.global_position + Vector2(48, 0)
	foe.health = 100.0
	var shots: int = 0
	var n: int = 0
	while n < 20:
		var fire: Array[Dictionary] = _idle(session)
		fire[0]["fire_held"] = true
		var before: int = session.bullets.size()
		session.step_fixed(STEP, fire)
		if session.bullets.size() > before:
			shots += 1
		n += 1
	print(
		"HH_PROBE UZI_AUTO shots=%d ammo=%d foe_hp=%.1f bullets=%d"
		% [shots, p1.ammo, foe.health, session.bullets.size()]
	)


func _probe_title(app: App) -> void:
	var label: Label = app.title.get_node_or_null("TitleLabel") as Label
	var sub: Label = app.title.get_node_or_null("Subtitle") as Label
	var hint: Label = app.title.get_node_or_null("InputHint") as Label
	var hint2: Label = app.title.get_node_or_null("InputHint2") as Label
	var blob: String = ""
	if label != null:
		blob += label.text
	if sub != null:
		blob += " | " + sub.text
	if hint != null:
		blob += " | " + hint.text
	if hint2 != null:
		blob += " | " + hint2.text
	var tm: bool = blob.to_lower().contains("superfighter")
	print("HH_PROBE TITLE text=%s trademark=%s" % [blob, tm])
