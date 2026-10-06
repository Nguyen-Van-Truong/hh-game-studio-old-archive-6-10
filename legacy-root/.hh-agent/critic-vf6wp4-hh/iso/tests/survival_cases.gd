class_name SurvivalCases
extends RefCounted

## VF6-WP4 Survival director. Official proof is title Survival
## click, live rooftops play, score/spawn/pause, then death
## game-over and rematch that clears the director.
## No force_kill. No teleport. Bots stay smoke.

const _Survival: GDScript = preload("res://src/sim/survival.gd")
const _Stage: GDScript = preload("res://src/sim/stage.gd")
const RUN_ID := "VF6WP4-20260903-ASIA-SAIGON-01"

static var used_step_fixed: int = 0
static var used_apply_frames: int = 0
static var used_apply_frames_attempted: int = 0
static var used_apply_frames_succeeded: int = 0
static var used_parse_input_event: int = 0
static var used_action_press: int = 0
static var used_force_kill: int = 0
static var used_teleport: int = 0
static var used_apply_eval: int = 0
static var outcome_schema: Dictionary = {}
static var outcome_load: Dictionary = {}
static var outcome_distinct: Dictionary = {}
static var outcome_score: Dictionary = {}
static var outcome_spawn: Dictionary = {}
static var outcome_pause: Dictionary = {}
static var outcome_restart: Dictionary = {}
static var outcome_live: Dictionary = {}
static var still_paths: Dictionary = {}
static var timeline: Array = []
static var snapshot_start: Dictionary = {}
static var snapshot_end: Dictionary = {}
static var events_all: Array = []
static var live_app: App = null
static var soak_elapsed: float = 0.0
static var soak_required: int = 0


static func soak_seconds() -> int:
	var env: String = OS.get_environment("HH_VF_SURVIVAL_SOAK_SEC")
	if env != "":
		return maxi(int(env), 0)
	if DisplayServer.get_name() == "headless":
		return 600
	return 300


static func run_all(app: App) -> PackedStringArray:
	used_step_fixed = 0
	used_apply_frames = 0
	used_apply_frames_attempted = 0
	used_apply_frames_succeeded = 0
	used_parse_input_event = 0
	used_action_press = 0
	used_force_kill = 0
	used_teleport = 0
	used_apply_eval = 0
	outcome_schema = {"verdict": "unproven"}
	outcome_load = {"verdict": "unproven"}
	outcome_distinct = {"verdict": "unproven"}
	outcome_score = {"verdict": "unproven"}
	outcome_spawn = {"verdict": "unproven"}
	outcome_pause = {"verdict": "unproven"}
	outcome_restart = {"verdict": "unproven"}
	outcome_live = {"verdict": "unproven"}
	still_paths = {}
	timeline = []
	snapshot_start = {}
	snapshot_end = {}
	events_all = []
	live_app = app
	soak_elapsed = 0.0
	soak_required = soak_seconds()
	_Survival.reset_records()
	_Stage.reset_progress()
	var errors: PackedStringArray = PackedStringArray()
	_append(errors, schema_contract())
	print("HH_VF_SURVIVAL STEP=records")
	_append(errors, records_stable())
	print("HH_VF_SURVIVAL STEP=title")
	_append(errors, await title_start(app))
	print("HH_VF_SURVIVAL STEP=distinct")
	_append(errors, await distinct_from_stage(app))
	print("HH_VF_SURVIVAL STEP=score_spawn")
	_append(errors, await score_and_spawn(app))
	print("HH_VF_SURVIVAL STEP=pause")
	_append(errors, await pause_resume(app))
	print("HH_VF_SURVIVAL STEP=soak")
	_append(errors, await soak_run(app))
	print("HH_VF_SURVIVAL STEP=restart")
	_append(errors, await gameover_restart(app))
	_append(errors, _require_outcomes())
	return errors


static func schema_contract() -> PackedStringArray:
	var errors: PackedStringArray = _Survival.validate()
	var payload: Dictionary = _Survival.data()
	if str(payload.get("loop_class", "")) != "approximation":
		errors.append("survival loop must stay approximation")
	if bool(payload.get("y8_parity_claimed", true)):
		errors.append("survival must not claim Y8 parity")
	var match_row: Dictionary = MatchRules.mode_row("survival")
	if not bool(match_row.get("shipped", false)) or not bool(match_row.get("uses_machine", false)):
		errors.append("match survival must ship and use the machine")
	outcome_schema = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"source": "data/sim/survival.json",
		"loop_class": str(payload.get("loop_class", "")),
		"wave_class": str(payload.get("wave_class", "")),
		"score_class": str(payload.get("score_class", "")),
	}
	return errors


static func records_stable() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	_Survival.reset_records()
	var first: Dictionary = _Survival.record_finish(120, 1, 2)
	var h1: String = str(first.get("record_hash", ""))
	var again: Dictionary = _Survival.record_finish(80, 0, 1)
	var h2: String = str(again.get("record_hash", ""))
	if h1 == "" or int(first.get("best_score", 0)) != 120:
		errors.append("RECORD first finish must keep best 120")
	if int(again.get("best_score", 0)) != 120:
		errors.append("RECORD lower score must not replace best")
	if h2 == "" or h2 == h1:
		errors.append("RECORD runs increment must change hash")
	if int(again.get("runs", 0)) != 2:
		errors.append("RECORD must count runs")
	_Survival.reset_records()
	return errors


static func title_start(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.restart_to_title()
	await _ui_frames(app)
	still_paths["title"] = await _capture_still(app, "survival_title")
	if app.title == null or app.title.survival_btn == null:
		errors.append("TITLE missing Survival button")
		outcome_load = {"verdict": "fail"}
		return errors
	if app.title.stage_btn != null and app.title.stage_btn.text.contains("Survival"):
		errors.append("TITLE Stage must not be labeled Survival")
	if app.title.survival_btn.text != "Survival":
		errors.append("TITLE Survival button must say Survival")
	await _activate_button(app, app.title.survival_btn, "fight")
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var ok: bool = (
		session != null
		and session.mode == "survival"
		and session.map_id != ""
		and session.survival != null
		and session.outcome == "play"
	)
	if not ok:
		errors.append(
			"TITLE Survival missed session mode=%s map=%s"
			% [str(session.mode if session != null else ""), str(session.map_id if session != null else "")]
		)
	if session != null and snapshot_start.is_empty():
		snapshot_start = session.snapshot()
	still_paths["fight"] = await _capture_still(app, "survival_fight")
	_note("fight_start", session, {"mode": session.mode if session != null else ""})
	outcome_load = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"mode": session.mode if session != null else "",
		"map_id": session.map_id if session != null else "",
		"score": session.survival.score if session != null and session.survival != null else -1,
		"source": "title Survival click; no Stage continue",
	}
	return errors


static func distinct_from_stage(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var before: Dictionary = _Stage.load_or_empty()
	var hash_before: String = str(before.get("reward_hash", ""))
	var idx_before: int = int(before.get("current_index", -1))
	var session: GameSession = app.session
	if session == null or session.mode != "survival":
		errors.append("DISTINCT need a live Survival session")
	if session != null and session.mode == "stage":
		errors.append("DISTINCT Survival must not be Stage")
	if app.mode == "stage":
		errors.append("DISTINCT app.mode must be survival")
	var n: int = 0
	while n < 90 and app.session != null and app.session.outcome == "play":
		_tick_driven(app, _idle_cmd(), {})
		n += 1
	var after: Dictionary = _Stage.load_or_empty()
	if str(after.get("reward_hash", "")) != hash_before:
		errors.append("DISTINCT Survival must not change Stage reward hash")
	if int(after.get("current_index", -2)) != idx_before:
		errors.append("DISTINCT Survival must not change Stage index")
	if int(after.get("score", -1)) != int(before.get("score", -2)):
		errors.append("DISTINCT Survival must not change Stage score")
	if app.title != null and app.title.stage_btn != null:
		var cap: String = app.title.stage_btn.text
		if cap.contains("Survival"):
			errors.append("DISTINCT Stage caption must stay Stage")
	outcome_distinct = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"stage_hash_before": hash_before,
		"stage_hash_after": str(after.get("reward_hash", "")),
		"stage_index": idx_before,
		"survival_mode": session.mode if session != null else "",
		"source": "Survival play leaves Stage checkpoint untouched",
	}
	_note("distinct", app.session, {"stage_hash": hash_before})
	return errors


static func score_and_spawn(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var session: GameSession = app.session
	if session == null or session.survival == null:
		errors.append("SCORE missing survival director")
		outcome_score = {"verdict": "fail"}
		outcome_spawn = {"verdict": "fail"}
		return errors
	var samples: Array = []
	var max_bots: int = 0
	var max_pickups: int = 0
	var cap: int = SurvivalRules.cap_living_bots()
	var cap_pick: int = SurvivalRules.cap_pickups()
	var prev: int = session.survival.score
	var n: int = 0
	while n < 360 and session != null and session.outcome == "play":
		_tick_driven(app, _idle_cmd(), {})
		session = app.session
		if session == null or session.survival == null:
			break
		var now: int = session.survival.score
		samples.append(now)
		if now < prev:
			errors.append("SCORE decreased %d -> %d" % [prev, now])
			break
		prev = now
		max_bots = maxi(max_bots, session.living_bot_count())
		max_pickups = maxi(max_pickups, session.pickups.size())
		if session.living_bot_count() > cap:
			errors.append("SPAWN living bots %d over cap %d" % [session.living_bot_count(), cap])
			break
		if session.pickups.size() > cap_pick:
			errors.append("SPAWN pickups %d over cap %d" % [session.pickups.size(), cap_pick])
			break
		n += 1
	session = app.session
	var mono: bool = samples.size() >= 2 and int(samples[samples.size() - 1]) >= int(samples[0])
	if not mono:
		errors.append("SCORE need monotonic samples got %d" % samples.size())
	if session != null and session.survival != null and session.survival.score <= 0:
		errors.append("SCORE must increase during play")
		mono = false
	if max_bots > cap:
		errors.append("SPAWN cap broken")
	outcome_score = {
		"verdict": "pass" if mono and errors.is_empty() else "fail",
		"first": int(samples[0]) if not samples.is_empty() else -1,
		"last": int(samples[samples.size() - 1]) if not samples.is_empty() else -1,
		"samples": samples.size(),
		"source": "time/kill score never decreases during a run",
	}
	outcome_spawn = {
		"verdict": "pass" if max_bots <= cap and max_pickups <= cap_pick and session != null else "fail",
		"max_living_bots": max_bots,
		"cap_living_bots": cap,
		"max_pickups": max_pickups,
		"cap_pickups": cap_pick,
		"refused": session.survival.refused_spawns if session != null and session.survival != null else -1,
		"weapon_respawns": session.survival.weapon_respawns if session != null and session.survival != null else -1,
		"source": "director budget never exceeds entity caps",
	}
	if str(outcome_spawn.get("verdict", "")) != "pass":
		errors.append("SPAWN budget not bounded")
	_note("score_spawn", session, {"score": session.survival.score if session != null and session.survival != null else -1, "max_bots": max_bots})
	return errors


static func pause_resume(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var session: GameSession = app.session
	if session == null or session.survival == null or session.outcome != "play":
		errors.append("PAUSE need a live Survival run")
		outcome_pause = {"verdict": "fail"}
		return errors
	var tick0: int = session.clock.tick
	var score0: int = session.survival.score
	var hash0: String = session.snapshot_hash()
	session.set_paused(true, RuntimeConstants.REASON_PLAYER)
	await _ui_frames(app)
	var n: int = 0
	while n < 30:
		_tick_driven(app, _idle_cmd(), {})
		n += 1
	var tick1: int = session.clock.tick
	var score1: int = session.survival.score
	var hash1: String = session.snapshot_hash()
	var frozen: bool = tick1 == tick0 and score1 == score0 and hash1 == hash0
	if not frozen:
		errors.append("PAUSE must freeze tick/score/hash")
	session.set_paused(false)
	await _ui_frames(app)
	_tick_driven(app, _idle_cmd(), {})
	var tick2: int = session.clock.tick if session.clock != null else -1
	if tick2 <= tick1:
		errors.append("RESUME must advance sim tick")
	still_paths["pause"] = await _capture_still(app, "survival_pause")
	outcome_pause = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"tick0": tick0,
		"tick1": tick1,
		"tick2": tick2,
		"score0": score0,
		"score1": score1,
		"source": "pause freezes director; resume continues the same run",
	}
	_note("pause", session, {"tick0": tick0, "tick2": tick2})
	return errors


static func soak_run(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var need: int = soak_seconds()
	soak_required = need
	var t0: float = Time.get_unix_time_from_system()
	var last_score: int = -1
	var max_bots: int = 0
	var rematch_count: int = 0
	while Time.get_unix_time_from_system() - t0 < float(need):
		if app.session == null or app.session.outcome != "play" or app.session.mode != "survival":
			if rematch_count > 8:
				errors.append("SOAK rematch loop")
				break
			if app.lose_screen != null and app.lose_screen.visible and app.lose_screen.rematch_btn != null:
				await _activate_button(app, app.lose_screen.rematch_btn, "rematch")
				await SimReplay.sync_physics(app)
				rematch_count += 1
			elif app.title != null and app.title.visible and app.title.survival_btn != null:
				await _activate_button(app, app.title.survival_btn, "fight")
				await SimReplay.sync_physics(app)
				rematch_count += 1
			else:
				app.start_fight("survival", "rooftops", 0)
				await SimReplay.sync_physics(app)
				rematch_count += 1
			continue
		var session: GameSession = app.session
		var k: int = 0
		while k < 20 and session != null and session.outcome == "play":
			_tick_driven(app, _idle_cmd(), {})
			k += 1
		session = app.session
		if session != null and session.survival != null:
			if last_score >= 0 and session.survival.score < last_score and rematch_count == 0:
				errors.append("SOAK score decreased")
				break
			last_score = session.survival.score
			max_bots = maxi(max_bots, session.living_bot_count())
			if session.living_bot_count() > SurvivalRules.cap_living_bots():
				errors.append("SOAK spawn cap broken")
				break
		await _ui_frames(app)
	soak_elapsed = Time.get_unix_time_from_system() - t0
	if soak_elapsed + 0.5 < float(need):
		errors.append("SOAK elapsed %.1f < required %d" % [soak_elapsed, need])
	if max_bots > SurvivalRules.cap_living_bots():
		errors.append("SOAK max bots over cap")
	_note("soak", app.session, {"elapsed": soak_elapsed, "required": need, "max_bots": max_bots})
	print("HH_VF_SURVIVAL SOAK_SEC=%d ELAPSED=%.2f MAX_BOTS=%d REMATCH=%d" % [need, soak_elapsed, max_bots, rematch_count])
	if not errors.is_empty() and str(outcome_score.get("verdict", "")) == "pass":
		pass
	return errors


static func gameover_restart(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if app.session == null or app.session.mode != "survival" or app.session.outcome != "play":
		app.start_fight("survival", "rooftops", 0)
		await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	var stage_before: Dictionary = _Stage.load_or_empty()
	var fight: Dictionary = await _force_p1_down(app)
	session = app.session
	var score_shown: int = 0
	if session != null and session.survival != null:
		score_shown = session.survival.score
	var lost: bool = (
		session != null
		and session.outcome == "lose"
		and session.mode == "survival"
		and app.lose_screen != null
		and app.lose_screen.visible
	)
	if not lost:
		errors.append(
			"RESTART need Survival game-over got outcome=%s mode=%s"
			% [str(session.outcome if session != null else ""), str(session.mode if session != null else "")]
		)
	still_paths["lose"] = await _capture_still(app, "survival_lose")
	_note("gameover", session, {"score": score_shown, "cause": str(fight.get("death_cause", ""))})
	_harvest(session)
	if app.lose_screen != null and app.lose_screen.rematch_btn != null:
		await _activate_button(app, app.lose_screen.rematch_btn, "rematch")
		await SimReplay.sync_physics(app)
	session = app.session
	var cleared: bool = (
		session != null
		and session.mode == "survival"
		and session.outcome == "play"
		and session.survival != null
		and session.survival.score == 0
		and session.survival.wave_index == 0
		and session.survival.combo == 0
		and not session.survival.finished
	)
	if not cleared:
		errors.append(
			"RESTART rematch must clear director score=%s wave=%s"
			% [
				str(session.survival.score if session != null and session.survival != null else ""),
				str(session.survival.wave_index if session != null and session.survival != null else ""),
			]
		)
	var stage_after: Dictionary = _Stage.load_or_empty()
	if str(stage_after.get("reward_hash", "")) != str(stage_before.get("reward_hash", "")):
		errors.append("RESTART must not mutate Stage save")
	still_paths["restart"] = await _capture_still(app, "survival_restart")
	if session != null and is_instance_valid(session):
		snapshot_end = session.snapshot()
		_harvest(session)
	app.restart_to_title()
	await _ui_frames(app)
	still_paths["title_after"] = await _capture_still(app, "survival_title_after")
	if app.session != null and is_instance_valid(app.session):
		snapshot_end = app.session.snapshot()
		_harvest(app.session)
	outcome_restart = {
		"verdict": "pass" if lost and cleared else "fail",
		"lost": lost,
		"cleared": cleared,
		"score_shown": score_shown,
		"death_cause": str(fight.get("death_cause", "")),
		"end_reason": str(fight.get("end_reason", "")),
		"source": "P1 death ends the run and shows score; rematch is a new run",
	}
	outcome_live = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"title_visible_after": app.title != null and app.title.visible,
		"timeline_len": timeline.size(),
		"events_len": events_all.size(),
		"soak_elapsed": soak_elapsed,
		"soak_required": soak_required,
		"source": "title Survival click + live apply_frames + rematch clears director",
	}
	live_app = app
	return errors


static func _force_p1_down(app: App) -> Dictionary:
	var out: Dictionary = {"ok": false, "death_cause": "", "end_reason": ""}
	var session: GameSession = app.session
	if session == null:
		return out
	_sanitize_input(app)
	var cycle: int = 0
	var stuck: int = 0
	var last_x: float = 0.0
	var last_hp: float = 100.0
	var hp_stall: int = 0
	var use_pit: bool = false
	var p1: Fighter = session.player1()
	if p1 != null:
		last_x = p1.global_position.x
		last_hp = p1.health
	while cycle < 3600 and session != null and session.outcome == "play":
		p1 = session.player1()
		var foe: Fighter = _first_living_foe(session)
		if p1 == null:
			break
		if absf(p1.global_position.x - last_x) < 1.0:
			stuck += 1
		else:
			stuck = 0
			last_x = p1.global_position.x
		if p1.health < last_hp - 0.5:
			hp_stall = 0
		else:
			hp_stall += 1
		last_hp = p1.health
		var far: bool = foe == null or absf(foe.global_position.x - p1.global_position.x) > 40.0
		if (not use_pit) and cycle > 1200 and hp_stall > 240 and not far:
			use_pit = true
		if use_pit:
			await _tick_driven(app, _pit_walk(session, p1, stuck), {})
		elif foe != null:
			await _tick_driven(app, _hunt_p1(session, p1, foe, stuck), _bot_attack(session, p1))
		else:
			await _tick_driven(app, _idle_cmd(), {})
		if cycle % 20 == 0:
			await _ui_frames(app)
		if cycle % 90 == 0:
			print(
				"HH_VF_SURVIVAL HUNT tick=%s p1=(%.1f,%.1f) foe=%s p1_hp=%.1f bots=%d stuck=%d pit=%s"
				% [
					str(session.clock.tick if session.clock != null else -1),
					p1.global_position.x,
					p1.global_position.y,
					str(foe.global_position if foe != null else Vector2.ZERO),
					p1.health,
					session.living_bot_count(),
					stuck,
					str(use_pit),
				]
			)
		cycle += 1
		session = app.session
	session = app.session
	var p1b: Fighter = session.player1() if session != null else null
	out["death_cause"] = p1b.death_cause if p1b != null else ""
	out["end_reason"] = session.match_rules.end_reason if session != null and session.match_rules != null else ""
	out["outcome"] = session.outcome if session != null else ""
	out["ok"] = session != null and session.outcome == "lose"
	out["cycles"] = cycle
	print(
		"HH_VF_SURVIVAL RESOLVE lose ok=%s cause=%s outcome=%s tick=%s cycles=%d"
		% [
			str(out["ok"]),
			str(out["death_cause"]),
			str(out.get("outcome", "")),
			str(session.clock.tick if session != null and session.clock != null else -1),
			cycle,
		]
	)
	return out


static func _require_outcomes() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var labels: PackedStringArray = PackedStringArray([
		"schema", "load", "distinct", "score", "spawn", "pause", "restart", "live"
	])
	var rows: Array = [
		outcome_schema, outcome_load, outcome_distinct, outcome_score,
		outcome_spawn, outcome_pause, outcome_restart, outcome_live,
	]
	var i: int = 0
	while i < labels.size():
		var row: Dictionary = rows[i] as Dictionary
		if str(row.get("verdict", "")) != "pass":
			errors.append("%s outcome is %s" % [String(labels[i]), str(row.get("verdict", "unproven"))])
		i += 1
	if used_force_kill != 0:
		errors.append("official survival used force_kill")
	if used_teleport != 0:
		errors.append("official survival used teleport")
	if used_step_fixed != 0:
		errors.append("official survival used step_fixed")
	if used_apply_eval != 0:
		errors.append("official survival used apply_eval")
	if timeline.is_empty():
		errors.append("official survival need a timeline")
	return errors


static func _first_living_foe(session: GameSession) -> Fighter:
	if session == null:
		return null
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		i += 1
		if f != null and f.is_bot and not f.dead:
			return f
	return null


static func _hunt_p1(session: GameSession, p1: Fighter, foe: Fighter, stuck: int) -> Dictionary:
	var cmd: Dictionary = _idle_cmd()
	if p1 == null:
		return cmd
	var x: float = p1.global_position.x
	var y: float = p1.global_position.y
	if foe != null:
		var dx: float = foe.global_position.x - x
		var dy: float = foe.global_position.y - y
		if absf(dx) <= 28.0 and absf(dy) <= 22.0:
			## Stay ~16px in front so melee is not stacked / behind.
			if absf(dx) < 12.0:
				cmd["x"] = -1.0 if dx >= 0.0 else 1.0
			elif absf(dx) > 20.0:
				cmd["x"] = 1.0 if dx >= 0.0 else -1.0
			return cmd
		if dy < -16.0:
			cmd["jump"] = true
			cmd["jump_pressed"] = (session.clock.tick % 8) == 0
			if absf(dx) > 8.0:
				cmd["x"] = 1.0 if dx >= 0.0 else -1.0
			return cmd
	if session != null and session.map_id == "rooftops":
		if y > 108.0 and x < 190.0:
			if x < 155.0:
				cmd["x"] = 1.0
				return cmd
			cmd["jump"] = true
			cmd["jump_pressed"] = (session.clock.tick % 8) == 0
			return cmd
		if y <= 110.0 and x < 430.0:
			cmd["x"] = 1.0
			if x < 200.0:
				cmd["jump_pressed"] = (session.clock.tick % 6) == 0
			return cmd
	if foe != null:
		cmd["x"] = 1.0 if foe.global_position.x >= x else -1.0
	if stuck > 24:
		cmd["jump"] = true
		cmd["jump_pressed"] = (stuck % 14) == 0
	return cmd


static func _pit_walk(session: GameSession, p1: Fighter, stuck: int) -> Dictionary:
	var cmd: Dictionary = _idle_cmd()
	if p1 == null:
		return cmd
	var x: float = p1.global_position.x
	var y: float = p1.global_position.y
	## Same live KEY_RIGHT pit walk as VF6-WP1, after the rooftops climb.
	if y > 108.0 and x < 190.0:
		if x < 155.0:
			cmd["x"] = 1.0
			return cmd
		cmd["jump"] = true
		cmd["jump_pressed"] = (session.clock.tick % 8) == 0
		return cmd
	cmd["x"] = 1.0
	if y <= 110.0 and x > 400.0:
		cmd["crouch"] = true
		cmd["crouch_pressed"] = true
	if stuck > 18:
		cmd["jump"] = true
		cmd["jump_pressed"] = (stuck % 12) == 0
	return cmd


static func _bot_attack(session: GameSession, p1: Fighter) -> Dictionary:
	var out: Dictionary = {}
	if session == null or p1 == null:
		return out
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		i += 1
		if f == null or not f.is_bot or f.dead:
			continue
		var cmd: Dictionary = _idle_cmd()
		var dx: float = p1.global_position.x - f.global_position.x
		var dy: float = p1.global_position.y - f.global_position.y
		cmd["x"] = 1.0 if dx >= 0.0 else -1.0
		if dy < -12.0:
			cmd["jump"] = true
			cmd["jump_pressed"] = (session.clock.tick % 8) == 0
		if absf(dx) <= 28.0 and absf(dy) <= 22.0:
			cmd["melee"] = (session.clock.tick % 3) == 0
		else:
			cmd["melee"] = (session.clock.tick % 10) == 0
		out[f.slot] = cmd
	return out


static func _idle_cmd() -> Dictionary:
	return {
		"x": 0.0,
		"jump": false,
		"jump_pressed": false,
		"crouch": false,
		"crouch_pressed": false,
		"melee": false,
		"roll": false,
		"dive": false,
		"kick": false,
		"fire_held": false,
		"fire_released": false,
	}


static func _tick_driven(app: App, p1_cmd: Dictionary, bot_cmds: Dictionary) -> void:
	if app == null or app.session == null:
		return
	var session: GameSession = app.session
	_sanitize_input(app)
	_inject_p1_cmd(app, p1_cmd)
	var frames: Array = []
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		if f != null and f.is_human and f.slot == 0:
			frames.append(InputActions.frame_from_cmd(p1_cmd, session.clock.tick, 0))
		elif f != null and bot_cmds.has(f.slot):
			var raw: Dictionary = (bot_cmds[f.slot] as Dictionary).duplicate(true)
			frames.append(InputActions.frame_from_cmd(raw, session.clock.tick, f.slot))
		else:
			frames.append(InputFrame.from_dict(InputActions.empty_frame(session.clock.tick, i)))
		i += 1
	used_apply_frames_attempted += 1
	if session.apply_frames(frames):
		used_apply_frames_succeeded += 1
		used_apply_frames += 1
	_release_all_p1(app)


static func _inject_p1_cmd(app: App, cmd: Dictionary) -> void:
	if app == null or app.get_viewport() == null:
		return
	var vp: Viewport = app.get_viewport()
	var x: float = float(cmd.get("x", 0.0))
	if x > 0.35:
		InputInjector.inject_key(KEY_RIGHT, true, vp)
		used_parse_input_event += 1
	elif x < -0.35:
		InputInjector.inject_key(KEY_LEFT, true, vp)
		used_parse_input_event += 1
	if bool(cmd.get("jump", false)) or bool(cmd.get("jump_pressed", false)):
		InputInjector.inject_key(KEY_UP, true, vp)
		used_parse_input_event += 1
	if bool(cmd.get("crouch", false)) or bool(cmd.get("crouch_pressed", false)):
		InputInjector.inject_key(KEY_DOWN, true, vp)
		used_parse_input_event += 1
	if bool(cmd.get("melee", false)):
		InputInjector.inject_key(KEY_N, true, vp)
		used_parse_input_event += 1


static func _release_all_p1(app: App) -> void:
	if app == null or app.get_viewport() == null:
		InputActions.reset_edges()
		return
	var vp: Viewport = app.get_viewport()
	var keys: Array = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_N]
	var i: int = 0
	while i < keys.size():
		InputInjector.inject_key(keys[i] as Key, false, vp)
		i += 1
	InputActions.reset_edges()


static func _activate_button(app: App, btn: Button, kind: String) -> void:
	if app == null or btn == null:
		return
	var before: String = _probe(app, kind)
	used_parse_input_event += 1
	btn.grab_focus()
	await _ui_frames(app)
	_click_control(app, btn)
	await _ui_frames(app)
	if _probe(app, kind) != before:
		return
	_push_key(app, KEY_ENTER)
	await _ui_frames(app)
	if _probe(app, kind) != before:
		return
	_push_action(app, "ui_accept")
	await _ui_frames(app)


static func _probe(app: App, kind: String) -> String:
	if kind == "fight":
		return "1" if app.session != null else "0"
	if kind == "rematch":
		if app.session != null and app.session.match_rules != null:
			return "%d:%s" % [app.session.match_rules.round_id, app.session.get_instance_id()]
		return "0"
	return ""


static func _sanitize_input(app: App) -> void:
	if app == null or app.get_viewport() == null:
		InputActions.reset_edges()
		return
	var vp: Viewport = app.get_viewport()
	InputInjector.release_known(vp)
	Input.flush_buffered_events()
	InputInjector.release_known(vp)
	InputActions.reset_edges()


static func _ui_frames(app: App) -> void:
	if app == null or app.get_tree() == null:
		return
	var tree: SceneTree = app.get_tree()
	await tree.process_frame
	await tree.process_frame


static func _mouse_at(ctrl: Control, pressed: bool) -> InputEventMouseButton:
	var pos: Vector2 = ctrl.get_global_rect().get_center()
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	return ev


static func _inject_mouse(app: App, ev: InputEventMouseButton) -> void:
	if app == null or app.get_viewport() == null:
		return
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	app.get_viewport().push_input(ev, true)
	used_parse_input_event += 1


static func _click_control(app: App, ctrl: Control) -> void:
	if app == null or ctrl == null or app.get_viewport() == null:
		return
	_inject_mouse(app, _mouse_at(ctrl, true))
	_inject_mouse(app, _mouse_at(ctrl, false))


static func _push_key(app: App, key: Key) -> void:
	if app == null:
		return
	var vp: Viewport = app.get_viewport()
	InputInjector.inject_key(key, true, vp)
	used_parse_input_event += 1
	InputInjector.inject_key(key, false, vp)
	used_parse_input_event += 1


static func _push_action(app: App, action: String) -> void:
	if app == null or app.get_viewport() == null:
		return
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	app.get_viewport().push_input(ev)
	used_parse_input_event += 1
	var rel: InputEventAction = InputEventAction.new()
	rel.action = action
	rel.pressed = false
	app.get_viewport().push_input(rel)
	used_parse_input_event += 1


static func _capture_still(app: App, stem: String) -> String:
	var ev: String = OS.get_environment("HH_VF_EVIDENCE_DIR")
	if ev == "":
		ev = ProjectSettings.globalize_path("res://.evidence/%s" % RUN_ID)
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
	var err: Error = img.save_png(shot)
	print("HH_VF_SURVIVAL SCREENSHOT_%s err=%d path=%s" % [stem, int(err), shot])
	return shot


static func _note(at: String, session: GameSession, extra: Dictionary) -> void:
	var row: Dictionary = extra.duplicate(true)
	row["at"] = at
	if session != null:
		row["map_id"] = session.map_id
		row["mode"] = session.mode
		row["tick"] = session.clock.tick if session.clock != null else -1
		row["outcome"] = session.outcome
		row["living_bots"] = session.living_bot_count()
		if session.survival != null:
			row["score"] = session.survival.score
			row["wave"] = session.survival.wave_index
	timeline.append(row)


static func _harvest(session: GameSession) -> void:
	if session == null or not is_instance_valid(session) or session.ledger == null:
		return
	var rows: Array = session.ledger.to_array()
	var i: int = 0
	while i < rows.size():
		var raw: Variant = rows[i]
		i += 1
		if not (raw is Dictionary):
			continue
		var copy: Dictionary = (raw as Dictionary).duplicate(true)
		copy["map_id"] = session.map_id
		copy["mode"] = session.mode
		events_all.append(copy)


static func _append(into: PackedStringArray, extra: PackedStringArray) -> void:
	var i: int = 0
	while i < extra.size():
		into.append(String(extra[i]))
		i += 1
