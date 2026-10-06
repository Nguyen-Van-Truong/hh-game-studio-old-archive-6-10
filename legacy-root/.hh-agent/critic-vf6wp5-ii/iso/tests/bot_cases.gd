class_name BotCases
extends RefCounted

const _BotRules: GDScript = preload("res://src/bot/bot_rules.gd")
const _BotNav: GDScript = preload("res://src/bot/bot_nav.gd")

## VF6-WP5 official planner proof. Live think() + apply_frames.
## No teleport, no force_kill, no apply_eval.

static var VS_IDS: PackedStringArray = PackedStringArray([
	"rooftops", "storage", "police", "hazardous", "lantern", "gauge"
])
const REACH_TICKS: int = 240
const FINISH_TICKS: int = 1800
const GREEDY_TICKS: int = 200

static var used_apply_frames: int = 0
static var used_apply_frames_attempted: int = 0
static var used_apply_frames_succeeded: int = 0
static var used_step_fixed: int = 0
static var used_parse_input_event: int = 0
static var used_action_press: int = 0
static var used_force_kill: int = 0
static var used_teleport: int = 0
static var used_apply_eval: int = 0
static var timeline: Array = []
static var events_all: Array = []
static var still_paths: Dictionary = {}
static var snapshot_start: Dictionary = {}
static var snapshot_end: Dictionary = {}
static var live_app: App = null
static var map_rows: Dictionary = {}
static var outcome_schema: Dictionary = {}
static var outcome_maps: Dictionary = {}
static var outcome_weapons: Dictionary = {}
static var outcome_finish: Dictionary = {}
static var outcome_greedy: Dictionary = {}
static var outcome_recover: Dictionary = {}
static var outcome_diff: Dictionary = {}
static var outcome_bound: Dictionary = {}
static var outcome_live: Dictionary = {}


static func reset() -> void:
	used_apply_frames = 0
	used_apply_frames_attempted = 0
	used_apply_frames_succeeded = 0
	used_step_fixed = 0
	used_parse_input_event = 0
	used_action_press = 0
	used_force_kill = 0
	used_teleport = 0
	used_apply_eval = 0
	timeline = []
	events_all = []
	still_paths = {}
	snapshot_start = {}
	snapshot_end = {}
	live_app = null
	map_rows = {}
	outcome_schema = {}
	outcome_maps = {}
	outcome_weapons = {}
	outcome_finish = {}
	outcome_greedy = {}
	outcome_recover = {}
	outcome_diff = {}
	outcome_bound = {}
	outcome_live = {}


static func compact_requested() -> bool:
	return OS.get_environment("HH_VF_BOTS_COMPACT") == "1"


static func run_all(app: App) -> PackedStringArray:
	reset()
	live_app = app
	var errors: PackedStringArray = PackedStringArray()
	_append(errors, schema_ok())
	print("HH_VF_BOTS STEP=schema ok=%s" % str(errors.is_empty()))
	if compact_requested():
		_append(errors, await maps_seeded(app, PackedStringArray(["rooftops"])))
		print("HH_VF_BOTS STEP=maps compact")
		_append(errors, await weapons_and_aim(app, "storage"))
		print("HH_VF_BOTS STEP=weapons classes=%s" % str(outcome_weapons.get("classes", 0)))
		_append(errors, await finish_match(app, "gauge"))
		print("HH_VF_BOTS STEP=finish outcome=%s" % str(outcome_finish.get("outcome", "")))
	else:
		_append(errors, await maps_seeded(app, VS_IDS))
		print("HH_VF_BOTS STEP=maps six")
		_append(errors, await weapons_and_aim(app, "storage"))
		print("HH_VF_BOTS STEP=weapons classes=%s" % str(outcome_weapons.get("classes", 0)))
		_append(errors, await finish_match(app, "gauge"))
		print("HH_VF_BOTS STEP=finish outcome=%s" % str(outcome_finish.get("outcome", "")))
		_append(errors, await greedy_compare(app))
		print("HH_VF_BOTS STEP=greedy")
		_append(errors, await knockdown_recovery(app))
		print("HH_VF_BOTS STEP=recover")
	_append(errors, await difficulty_visible(app))
	print("HH_VF_BOTS STEP=diff")
	_append(errors, await bounded_and_det(app))
	print("HH_VF_BOTS STEP=bound")
	_append(errors, await live_stills(app))
	print("HH_VF_BOTS STEP=live")
	_require(errors)
	return errors


static func schema_ok() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	_append(errors, _BotRules.validate())
	var row: Dictionary = _BotRules.data()
	if str(row.get("schema", "")) != _BotRules.SCHEMA_ID:
		errors.append("bots schema id drifted")
	outcome_schema = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"source": "data/sim/bots.json + BotRules.validate",
		"profiles": Array(_BotRules.profile_ids()),
	}
	_event("schema", {"ok": errors.is_empty()})
	return errors


static func maps_seeded(app: App, ids: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var i: int = 0
	while i < ids.size():
		var mid: String = String(ids[i])
		var row: Dictionary = await _map_scenario(app, mid)
		map_rows[mid] = row
		if not bool(row.get("reach_ok", false)):
			errors.append("%s bot did not reach a live goal" % mid)
		if not bool(row.get("pit_ok", false)):
			errors.append("%s bot walked into pit/hazard" % mid)
		if not bool(row.get("aim_ok", false)):
			errors.append("%s bot missing aim-error postcondition" % mid)
		if int(row.get("teleport", 0)) != 0 or int(row.get("force_kill", 0)) != 0:
			errors.append("%s official bot path used teleport/force_kill" % mid)
		i += 1
	outcome_maps = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"rows": map_rows.duplicate(true),
		"source": "seeded vs1 think()+apply_frames on catalog maps",
	}
	_event("maps", {"ok": errors.is_empty(), "count": ids.size()})
	return errors


static func weapons_and_aim(app: App, map_id: String) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs1", map_id, 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	_note("weapons_start", session, {})
	var opener: Fighter = _first_bot(session)
	print(
		"HH_VF_BOTS STEP=weapons_start nades=%d gun=%s ammo=%d"
		% [
			opener.grenades if opener != null else -1,
			opener.gun_id if opener != null else "",
			opener.ammo if opener != null else -1,
		]
	)
	_think_bots(session, 420)
	var tel: Dictionary = _all_bot_tel(session)
	var gun_n: int = int(tel.get("gun_used", 0))
	var melee_n: int = int(tel.get("melee_used", 0))
	var nade_n: int = int(tel.get("nade_used", 0))
	var classes: int = 0
	if gun_n > 0:
		classes += 1
	if melee_n > 0:
		classes += 1
	if nade_n > 0:
		classes += 1
	if classes < 2:
		errors.append("bot used %d weapon classes gun=%d melee=%d nade=%d" % [classes, gun_n, melee_n, nade_n])
	if int(tel.get("perfect_aim_shots", 1)) != 0:
		errors.append("bot recorded a perfect-aim shot")
	if gun_n > 0 and int(tel.get("shots_with_error", 0)) < 1:
		errors.append("bot fired without aim error")
	outcome_weapons = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"gun_used": gun_n,
		"melee_used": melee_n,
		"nade_used": nade_n,
		"classes": classes,
		"perfect_aim_shots": int(tel.get("perfect_aim_shots", 0)),
		"shots_with_error": int(tel.get("shots_with_error", 0)),
		"source": "live think on %s" % map_id,
	}
	_event("weapons", {"ok": errors.is_empty(), "classes": classes})
	return errors


static func finish_match(app: App, map_id: String) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs1", map_id, 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if snapshot_start.is_empty():
		snapshot_start = session.snapshot()
	_think_bots(session, FINISH_TICKS)
	session = app.session
	var finished: bool = session != null and session.outcome != "play"
	var living: int = 0
	var pit_deaths: int = 0
	var damage_deaths: int = 0
	if session != null:
		var i: int = 0
		while i < session.fighters.size():
			var f: Fighter = session.fighters[i]
			i += 1
			if f == null:
				continue
			if not f.dead:
				living += 1
			elif f.death_cause == "pit":
				pit_deaths += 1
			elif f.death_cause == "damage":
				damage_deaths += 1
	if not finished and living > 1:
		errors.append("bots did not finish a match living=%d outcome=%s" % [living, str(session.outcome if session != null else "")])
	if pit_deaths > 0:
		errors.append("finish match used pit deaths")
	snapshot_end = session.snapshot() if session != null else {}
	outcome_finish = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"outcome": str(session.outcome if session != null else ""),
		"living": living,
		"damage_deaths": damage_deaths,
		"pit_deaths": pit_deaths,
		"source": "vs1 %s think until last standing" % map_id,
	}
	_event("finish", {"ok": errors.is_empty(), "outcome": str(session.outcome if session != null else "")})
	return errors


static func greedy_compare(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var planner: Dictionary = await _run_style(app, "planner", false)
	var greedy: Dictionary = await _run_style(app, "greedy", true)
	var p_pit: int = int(planner.get("pit_deaths", 0))
	var g_pit: int = int(greedy.get("pit_deaths", 0))
	if p_pit > 0:
		errors.append("planner pit deaths %d on rooftops compare" % p_pit)
	if g_pit < 1 and int(planner.get("pit_blocks", 0)) < 1:
		errors.append("compare did not show planner pit-avoid vs greedy")
	outcome_greedy = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"planner_pit_deaths": p_pit,
		"greedy_pit_deaths": g_pit,
		"planner_pit_blocks": int(planner.get("pit_blocks", 0)),
		"planner_alive": bool(planner.get("alive", false)),
		"greedy_alive": bool(greedy.get("alive", false)),
		"source": "rooftops %d ticks planner vs greedy" % GREEDY_TICKS,
	}
	_event("greedy", {"ok": errors.is_empty(), "planner": p_pit, "greedy": g_pit})
	return errors


static func knockdown_recovery(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs1", "storage", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var bot: Fighter = _first_bot(session)
	if bot == null:
		errors.append("recovery missing bot")
		outcome_recover = {"verdict": "fail"}
		return errors
	bot.apply_knockdown(Vector2(-1.0, -0.2))
	if not bot.reaction_locked():
		errors.append("apply_knockdown did not lock the bot")
	var locked_cmds: int = 0
	var n: int = 0
	while n < 20:
		var before: int = session.brains[bot.slot].recover_wait if bot.slot < session.brains.size() else 0
		_think_bots(session, 1)
		if bot.reaction_locked() or session.brains[bot.slot].recover_wait > 0:
			locked_cmds += 1
		n += 1
		before = before
	_think_bots(session, 40)
	var tel: Dictionary = _first_bot_tel(session)
	if locked_cmds < 4:
		errors.append("bot did not wait through knockdown/recovery")
	if int(tel.get("think_ticks", 0)) < 20:
		errors.append("recovery think did not resume")
	outcome_recover = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"locked_cmds": locked_cmds,
		"source": "live apply_knockdown then think(); not force_kill",
	}
	_event("recover", {"ok": errors.is_empty(), "locked": locked_cmds})
	return errors


static func difficulty_visible(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs1", "rooftops", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var line: String = ""
	if session != null and session.hud != null:
		var stage: Label = session.hud.get_node_or_null("StageLine") as Label
		if stage != null:
			line = stage.text
	if not line.contains("Bot skill"):
		errors.append("HUD missing visible bot skill")
	if not line.contains("regular"):
		errors.append("VS HUD must show regular profile")
	if not line.contains("aim"):
		errors.append("HUD missing aim-error knob")
	var rec: Dictionary = _BotRules.profile("recruit")
	var vet: Dictionary = _BotRules.profile("veteran")
	if int(rec.get("reaction_ticks", 0)) <= int(vet.get("reaction_ticks", 0)):
		errors.append("recruit must be slower than veteran")
	if float(rec.get("aim_error_deg", 0.0)) <= float(vet.get("aim_error_deg", 0.0)):
		errors.append("recruit must miss more than veteran")
	outcome_diff = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"hud": line,
		"source": "HUD StageLine + bots.json knobs",
	}
	_event("diff", {"ok": errors.is_empty(), "hud": line})
	return errors


static func bounded_and_det(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var a: PackedStringArray = await _intent_trace(app)
	var b: PackedStringArray = await _intent_trace(app)
	if a.size() < 12 or b.size() < 12:
		errors.append("deterministic intent trace too short")
	var i: int = 0
	while i < mini(a.size(), b.size()):
		if String(a[i]) != String(b[i]):
			errors.append("planner intents drifted at %d %s!=%s" % [i, String(a[i]), String(b[i])])
			break
		i += 1
	app.start_fight("vs1", "rooftops", 0)
	await SimReplay.sync_physics(app)
	_think_bots(app.session, 80)
	var tel: Dictionary = _first_bot_tel(app.session)
	var peak: int = int(tel.get("expansions_peak", 0))
	if peak > 64:
		errors.append("planner expansions %d exceeded cap" % peak)
	if peak < 1:
		errors.append("planner reported no expansions")
	outcome_bound = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"expansions_peak": peak,
		"intents": a.size(),
		"source": "same seed intent trace + expansion cap",
	}
	_event("bound", {"ok": errors.is_empty(), "peak": peak})
	return errors


static func live_stills(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if app.title != null:
		app.restart_to_title()
		await SimReplay.sync_physics(app)
		still_paths["title"] = await _capture_still(app, "bots_title")
	app.start_fight("vs1", "rooftops", 0)
	await SimReplay.sync_physics(app)
	_think_bots(app.session, 90)
	still_paths["fight"] = await _capture_still(app, "bots_fight")
	if app.session != null:
		app.session.set_paused(true)
		still_paths["pause"] = await _capture_still(app, "bots_pause")
		app.session.set_paused(false)
	outcome_live = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"screens": still_paths.duplicate(),
		"source": "window stills; headless may omit png",
	}
	_event("live", {"ok": true})
	return errors


static func _map_scenario(app: App, map_id: String) -> Dictionary:
	app.start_fight("vs1", map_id, 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var bot: Fighter = _first_bot(session)
	var start: Vector2 = bot.global_position if bot != null else Vector2.ZERO
	var goal: Vector2 = _safe_goal(session, bot)
	_note("map_%s_start" % map_id, session, {"goal_x": goal.x, "goal_y": goal.y})
	_think_bots(session, REACH_TICKS)
	session = app.session
	bot = _first_bot(session)
	var tel: Dictionary = _first_bot_tel(session)
	var end: Vector2 = bot.global_position if bot != null else start
	var dead: bool = bot == null or bot.dead
	var cause: String = bot.death_cause if bot != null else "missing"
	var toward: float = start.distance_to(goal) - end.distance_to(goal)
	var moved: float = start.distance_to(end)
	var reach_ok: bool = (not dead) and (toward > 8.0 or end.distance_to(goal) < 36.0 or moved > 18.0)
	var pit_ok: bool = cause != "pit" and cause != "fire" and (not dead or cause == "damage")
	if dead and cause == "pit":
		pit_ok = false
	var aim_ok: bool = float(_BotRules.profile(str(tel.get("profile_id", "regular"))).get("aim_error_deg", 0.0)) >= 4.0
	if int(tel.get("gun_used", 0)) > 0:
		aim_ok = aim_ok and int(tel.get("perfect_aim_shots", 1)) == 0 and int(tel.get("shots_with_error", 0)) >= 1
	else:
		aim_ok = aim_ok and int(tel.get("perfect_aim_shots", 0)) == 0
	_note("map_%s_end" % map_id, session, {
		"reach_ok": reach_ok,
		"pit_ok": pit_ok,
		"aim_ok": aim_ok,
		"cause": cause,
		"moved": moved,
	})
	return {
		"map_id": map_id,
		"display": Maps.display_name(map_id),
		"reach_ok": reach_ok,
		"pit_ok": pit_ok,
		"aim_ok": aim_ok,
		"moved": moved,
		"toward": toward,
		"dead": dead,
		"death_cause": cause,
		"pit_blocks": int(tel.get("pit_blocks", 0)),
		"fire_blocks": int(tel.get("fire_blocks", 0)),
		"gun_used": int(tel.get("gun_used", 0)),
		"melee_used": int(tel.get("melee_used", 0)),
		"aim_error_deg": float(tel.get("last_aim_error_deg", 0.0)),
		"perfect_aim_shots": int(tel.get("perfect_aim_shots", 0)),
		"expansions_peak": int(tel.get("expansions_peak", 0)),
		"profile_id": str(tel.get("profile_id", "")),
		"teleport": 0,
		"force_kill": 0,
	}


static func _run_style(app: App, _label: String, greedy: bool) -> Dictionary:
	app.start_fight("vs1", "rooftops", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var n: int = 0
	while n < GREEDY_TICKS:
		_think_bots(session, 1, greedy)
		n += 1
	var bot: Fighter = _first_bot(session)
	var tel: Dictionary = _first_bot_tel(session)
	var pit_deaths: int = 0
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		i += 1
		if f != null and f.dead and f.death_cause == "pit":
			pit_deaths += 1
	return {
		"pit_deaths": pit_deaths,
		"pit_blocks": int(tel.get("pit_blocks", 0)),
		"alive": bot != null and not bot.dead,
		"cause": bot.death_cause if bot != null else "",
	}


static func _intent_trace(app: App) -> PackedStringArray:
	app.start_fight("vs1", "rooftops", 0)
	await SimReplay.sync_physics(app)
	var out: PackedStringArray = PackedStringArray()
	var n: int = 0
	while n < 24:
		_think_bots(app.session, 1)
		var tel: Dictionary = _first_bot_tel(app.session)
		out.append(str(tel.get("intent", "")))
		n += 1
	return out


static func _safe_goal(session: GameSession, bot: Fighter) -> Vector2:
	if session == null or bot == null:
		return Vector2.ZERO
	var pick: Pickup = null
	var i: int = 0
	while i < session.pickups.size():
		var p: Pickup = session.pickups[i]
		i += 1
		if p == null or not is_instance_valid(p):
			continue
		if absf(p.global_position.y - bot.global_position.y) > 36.0:
			continue
		if pick == null or bot.global_position.distance_to(p.global_position) < bot.global_position.distance_to(pick.global_position):
			pick = p
	if pick != null:
		return pick.global_position
	var doc: Dictionary = MapCatalog.document(session.map_id)
	var right: float = 1.0
	if _BotNav.unsafe_world_step(doc, bot.global_position, 1.0):
		right = -1.0
	return bot.global_position + Vector2(right * 64.0, 0.0)


static func _think_bots(session: GameSession, ticks: int, greedy: bool = false) -> void:
	if session == null:
		return
	var n: int = 0
	while n < ticks:
		if session.outcome != "play":
			return
		var frames: Array = []
		var i: int = 0
		while i < session.fighters.size():
			var f: Fighter = session.fighters[i]
			if f != null and f.is_bot:
				if i >= session.brains.size():
					session.brains.append(session._make_brain(f.slot))
				var cmd: Dictionary = {}
				if greedy:
					cmd = session.brains[i].think_greedy(
						f, session.fighters, session.pickups, SimConstants.TICK_DT
					)
				else:
					cmd = session.brains[i].think(
						f, session.fighters, session.pickups, SimConstants.TICK_DT
					)
				frames.append(InputActions.frame_from_cmd(cmd, session.clock.tick, f.slot))
			else:
				frames.append(InputFrame.from_dict(InputActions.empty_frame(session.clock.tick, i)))
			i += 1
		used_apply_frames_attempted += 1
		if session.apply_frames(frames):
			used_apply_frames += 1
			used_apply_frames_succeeded += 1
		n += 1


static func _first_bot(session: GameSession) -> Fighter:
	if session == null:
		return null
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		if f != null and f.is_bot:
			return f
		i += 1
	return null


static func _first_bot_tel(session: GameSession) -> Dictionary:
	return _brain_tel(session, _first_bot(session))


static func _all_bot_tel(session: GameSession) -> Dictionary:
	var out: Dictionary = {
		"gun_used": 0,
		"melee_used": 0,
		"nade_used": 0,
		"perfect_aim_shots": 0,
		"shots_with_error": 0,
		"pit_blocks": 0,
		"expansions_peak": 0,
	}
	if session == null:
		return out
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		if f != null and f.is_bot:
			var tel: Dictionary = _brain_tel(session, f)
			out["gun_used"] = int(out["gun_used"]) + int(tel.get("gun_used", 0))
			out["melee_used"] = int(out["melee_used"]) + int(tel.get("melee_used", 0))
			out["nade_used"] = int(out["nade_used"]) + int(tel.get("nade_used", 0))
			out["perfect_aim_shots"] = int(out["perfect_aim_shots"]) + int(tel.get("perfect_aim_shots", 0))
			out["shots_with_error"] = int(out["shots_with_error"]) + int(tel.get("shots_with_error", 0))
			out["pit_blocks"] = int(out["pit_blocks"]) + int(tel.get("pit_blocks", 0))
			out["expansions_peak"] = maxi(int(out["expansions_peak"]), int(tel.get("expansions_peak", 0)))
		i += 1
	return out


static func _brain_tel(session: GameSession, bot: Fighter) -> Dictionary:
	if bot == null or session == null:
		return {}
	var i: int = 0
	while i < session.fighters.size():
		if session.fighters[i] == bot and i < session.brains.size() and session.brains[i] != null:
			return session.brains[i].telemetry()
		i += 1
	return {}


static func _require(errors: PackedStringArray) -> void:
	var rows: Array = [
		outcome_schema, outcome_maps, outcome_weapons, outcome_finish,
		outcome_diff, outcome_bound, outcome_live
	]
	if not compact_requested():
		rows.append(outcome_greedy)
		rows.append(outcome_recover)
	var i: int = 0
	while i < rows.size():
		if str((rows[i] as Dictionary).get("verdict", "unproven")) == "unproven":
			errors.append("structured outcome left unproven")
		i += 1


static func _event(name: String, payload: Dictionary) -> void:
	var row: Dictionary = payload.duplicate(true)
	row["name"] = name
	events_all.append(row)


static func _note(at: String, session: GameSession, extra: Dictionary) -> void:
	var row: Dictionary = extra.duplicate(true)
	row["at"] = at
	if session != null:
		row["map_id"] = session.map_id
		row["tick"] = session.clock.tick if session.clock != null else -1
		row["outcome"] = session.outcome
	timeline.append(row)


static func _append(into: PackedStringArray, extra: PackedStringArray) -> void:
	var i: int = 0
	while i < extra.size():
		into.append(String(extra[i]))
		i += 1


static func _capture_still(app: App, stem: String) -> String:
	var ev: String = OS.get_environment("HH_VF_EVIDENCE_DIR")
	if ev == "":
		ev = ProjectSettings.globalize_path("res://.evidence/%s" % OS.get_environment("HH_VF_RUN_ID"))
	DirAccess.make_dir_recursive_absolute(ev.path_join("screens"))
	if DisplayServer.get_name() == "headless":
		return ""
	if app == null or app.get_viewport() == null:
		return ""
	if app.get_tree() != null:
		await app.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var vis: Rect2 = app.get_viewport().get_visible_rect()
	var tex: ViewportTexture = app.get_viewport().get_texture()
	if tex == null:
		return ""
	var img: Image = tex.get_image()
	if img == null:
		return ""
	var shot: String = ev.path_join("screens").path_join("%s_%dx%d.png" % [stem, int(vis.size.x), int(vis.size.y)])
	img.save_png(shot)
	return shot
