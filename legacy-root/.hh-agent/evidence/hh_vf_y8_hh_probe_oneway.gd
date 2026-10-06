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
	var i: int = 0
	while i < 6:
		await physics_frame
		i += 1
	await _jump_through(app, "police", Vector2i(9, 9), Vector2i(9, 11))
	await _jump_through(app, "rooftops", Vector2i(15, 5), Vector2i(8, 7))
	await _jump_through(app, "storage", Vector2i(14, 6), Vector2i(14, 8))
	if is_instance_valid(app):
		app.queue_free()
	quit(0)


func _idle(session: GameSession) -> Array[Dictionary]:
	var cmds: Array[Dictionary] = []
	var n: int = 0
	while n < session.fighters.size():
		cmds.append(InputActions.empty_cmd())
		n += 1
	return cmds


func _settle(session: GameSession, frames: int) -> void:
	var n: int = 0
	while n < frames:
		session.step_fixed(STEP, _idle(session))
		n += 1


func _jump_through(app: App, map_id: String, plat: Vector2i, stand: Vector2i) -> void:
	app.start_fight("vs1", map_id, 0)
	var session: GameSession = app.session
	var p1: Fighter = session.player1()
	var k: int = 0
	while k < 6:
		await physics_frame
		k += 1
	var top: float = float(plat.y * Maps.TILE)
	p1.global_position = Vector2(float(stand.x * Maps.TILE) + 8.0, float(stand.y * Maps.TILE) + 4.0)
	p1.velocity = Vector2.ZERO
	_settle(session, 14)
	var y0: float = p1.global_position.y
	var floor0: bool = p1.is_on_floor()
	var n: int = 0
	var min_y: float = y0
	var crossed: bool = false
	var blocked_under: bool = false
	while n < 42:
		var cmds: Array[Dictionary] = _idle(session)
		cmds[0]["jump"] = true
		cmds[0]["jump_pressed"] = n == 0
		session.step_fixed(STEP, cmds)
		var y: float = p1.global_position.y
		if y < min_y:
			min_y = y
		if y < top - 2.0:
			crossed = true
		# Still under the slab after the jump peak.
		n += 1
	if min_y > top + 2.0 and min_y < y0 - 8.0:
		blocked_under = true
	print(
		"HH_PROBE JUMPTHRU map=%s plat=%s stand=%s flag=%s floor0=%s y0=%.1f min_y=%.1f top=%.1f crossed=%s blocked_under=%s dead=%s"
		% [
			map_id,
			plat,
			stand,
			session.arena.platform_is_one_way(),
			floor0,
			y0,
			min_y,
			top,
			crossed,
			blocked_under,
			p1.dead,
		]
	)
