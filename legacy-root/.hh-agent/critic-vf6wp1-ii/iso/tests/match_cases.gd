class_name MatchCases
extends RefCounted

## VF6-WP1 canonical match state machine.
## Official proof is InputFrame apply_frames. No force_kill.
## 60 Hz is ledger:RL-SIM-FIXED-60 (assumption).
## Timer/countdown stay assumption, not observed.

const _Match: GDScript = preload("res://src/sim/match.gd")
const _Combat: GDScript = preload("res://src/sim/combat.gd")

const TRACE_DIR := "res://tests/traces/match"

static var used_step_fixed: int = 0
static var used_apply_frames: int = 0
static var used_apply_frames_attempted: int = 0
static var used_apply_frames_succeeded: int = 0
static var used_parse_input_event: int = 0
static var used_action_press: int = 0
static var used_force_kill: int = 0
static var outcome_schema: Dictionary = {}
static var outcome_machine: Dictionary = {}
static var outcome_win: Dictionary = {}
static var outcome_lose: Dictionary = {}
static var outcome_tie: Dictionary = {}
static var outcome_quit: Dictionary = {}
static var outcome_restart: Dictionary = {}
static var outcome_pause: Dictionary = {}
static var outcome_signal: Dictionary = {}
static var outcome_seed: Dictionary = {}
static var outcome_ff: Dictionary = {}
static var outcome_live: Dictionary = {}
static var outcome_replay: Dictionary = {}
static var snapshot_start: Dictionary = {}
static var snapshot_end: Dictionary = {}
static var events_all: Array = []


static func run_all(app: App) -> PackedStringArray:
	used_step_fixed = 0
	used_apply_frames = 0
	used_apply_frames_attempted = 0
	used_apply_frames_succeeded = 0
	used_parse_input_event = 0
	used_action_press = 0
	used_force_kill = 0
	outcome_schema = {"verdict": "unproven"}
	outcome_machine = {"verdict": "unproven"}
	outcome_win = {"verdict": "unproven"}
	outcome_lose = {"verdict": "unproven"}
	outcome_tie = {"verdict": "unproven"}
	outcome_quit = {"verdict": "unproven"}
	outcome_restart = {"verdict": "unproven"}
	outcome_pause = {"verdict": "unproven"}
	outcome_signal = {"verdict": "unproven"}
	outcome_seed = {"verdict": "unproven"}
	outcome_ff = {"verdict": "unproven"}
	outcome_live = {"verdict": "unproven"}
	outcome_replay = {"verdict": "unproven", "pairs": []}
	snapshot_start = {}
	snapshot_end = {}
	events_all = []
	var errors: PackedStringArray = PackedStringArray()
	_append(errors, schema_and_machine())
	_append(errors, await _capture_start(app))
	_append(errors, await replay_traces_twice(app))
	_append(errors, await win_last_standing(app))
	_append(errors, await lose_p1_down(app))
	_append(errors, await tie_timeout(app))
	_append(errors, await quit_to_title(app))
	_append(errors, await restart_fresh(app))
	_append(errors, await pause_freezes(app))
	_append(errors, await no_double_signal(app))
	_append(errors, spawn_seed_stable())
	_append(errors, await spawn_seed_from_session(app))
	_append(errors, ffa_team_table())
	_append(errors, friendly_fire_policy())
	_append(errors, await friendly_fire_runtime(app))
	_append(errors, await illegal_pause_resolve(app))
	_append(errors, await input_feedback_two_frames(app))
	_append(errors, await live_pause_inject(app))
	_append(errors, _require_outcomes())
	return errors


static func schema_and_machine() -> PackedStringArray:
	var errors: PackedStringArray = _Match.validate()
	var names: PackedStringArray = PackedStringArray([
		"match_win", "match_lose", "match_tie", "match_quit", "match_restart", "match_pause"
	])
	var listed: PackedStringArray = SimTrace.list_dir(TRACE_DIR)
	var have: PackedStringArray = PackedStringArray()
	var i: int = 0
	while i < listed.size():
		var path: String = String(listed[i])
		var trace: Dictionary = SimTrace.load_path(path)
		var verr: PackedStringArray = SimTrace.validate(trace)
		var j: int = 0
		while j < verr.size():
			errors.append("%s %s" % [path.get_file(), String(verr[j])])
			j += 1
		if str(trace.get("kind", "")) != "official":
			errors.append("%s must be official" % path.get_file())
		var dumped: String = JSON.stringify(trace)
		if dumped.contains("force_kill") or dumped.contains("teleport"):
			errors.append("%s official text contains fixture op" % path.get_file())
		have.append(str(trace.get("name", path.get_file())))
		i += 1
	i = 0
	while i < names.size():
		if not have.has(String(names[i])):
			errors.append("missing match trace %s" % String(names[i]))
		i += 1
	var modes: PackedStringArray = PackedStringArray(["vs1", "vs2", "stage", "survival"])
	i = 0
	while i < modes.size():
		var row: Dictionary = _Match.mode_row(String(modes[i]))
		if not bool(row.get("uses_machine", false)):
			errors.append("mode %s must use the canonical machine" % String(modes[i]))
		i += 1
	outcome_schema = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"source": "data/sim/match.json + traces",
	}
	outcome_machine = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"canonical": true,
		"modes": ["vs1", "vs2", "stage", "survival"],
		"source": "_Match.mode_row uses_machine",
	}
	return errors


static func replay_traces_twice(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var listed: PackedStringArray = SimTrace.list_dir(TRACE_DIR)
	var pairs: Array = []
	var all_match: bool = not listed.is_empty()
	var i: int = 0
	while i < listed.size():
		var path: String = String(listed[i])
		var a: Dictionary = await SimReplay.play_path(app, path)
		var b: Dictionary = await SimReplay.play_path(app, path)
		_remember_end(a)
		_append_events(a.get("events", []) as Array)
		if not bool(a.get("ok", false)):
			errors.append("replay %s run1 failed: %s" % [path.get_file(), _join(a)])
			all_match = false
		if not bool(b.get("ok", false)):
			errors.append("replay %s run2 failed: %s" % [path.get_file(), _join(b)])
			all_match = false
		if not bool(a.get("used_apply_frames", false)) or bool(a.get("used_cmd_dicts", true)):
			errors.append("%s MATCH used cmd dicts" % path.get_file())
			all_match = false
		if _has_kind(a, "force_kill"):
			errors.append("%s ledger has force_kill" % path.get_file())
			used_force_kill += 1
			all_match = false
		var ha: String = str(a.get("final_hash", ""))
		var hb: String = str(b.get("final_hash", ""))
		if ha == "" or ha != hb:
			errors.append("%s replay hashes differ" % path.get_file())
			all_match = false
		pairs.append({
			"name": path.get_file(),
			"hash": ha,
			"match": ha != "" and ha == hb,
			"outcome": str((a.get("final_state", {}) as Dictionary).get("outcome", "")),
		})
		i += 1
	outcome_replay = {
		"verdict": "match" if all_match and errors.is_empty() else "fail",
		"pair_count": pairs.size(),
		"pairs": pairs,
		"source": "SimReplay.final_hash twice",
	}
	return errors


static func win_last_standing(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var played: Dictionary = await SimReplay.play_path(app, "%s/match_win.json" % TRACE_DIR)
	_record_apply_batch(int(played.get("ticks", 0)), bool(played.get("ok", false)))
	_remember_end(played)
	_append_events(played.get("events", []) as Array)
	var state: Dictionary = played.get("final_state", {}) as Dictionary
	var reason: String = str(played.get("end_reason", ""))
	var ok: bool = (
		bool(played.get("ok", false))
		and str(state.get("outcome", "")) == "win"
		and reason == "last_standing"
		and not _has_kind(played, "force_kill")
		and _transition_has(played, "resolved")
		and _transition_post_ok(played, "resolved")
	)
	if not ok:
		errors.append("WIN last-standing apply_frames failed outcome=%s reason=%s" % [
			str(state.get("outcome", "")), reason
		])
	outcome_win = {
		"verdict": "pass" if ok else "fail",
		"outcome": str(state.get("outcome", "")),
		"end_reason": reason,
		"used_force_kill": _has_kind(played, "force_kill"),
		"source": "apply_frames match_win.json",
	}
	return errors


static func lose_p1_down(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var played: Dictionary = await SimReplay.play_path(app, "%s/match_lose.json" % TRACE_DIR)
	_record_apply_batch(int(played.get("ticks", 0)), bool(played.get("ok", false)))
	_remember_end(played)
	var state: Dictionary = played.get("final_state", {}) as Dictionary
	var reason: String = str(played.get("end_reason", ""))
	var ok: bool = (
		bool(played.get("ok", false))
		and str(state.get("outcome", "")) == "lose"
		and reason == "p1_down"
		and bool(state.get("p1_dead", false))
		and not _has_kind(played, "force_kill")
	)
	if not ok:
		errors.append("LOSE p1_down apply_frames failed outcome=%s reason=%s" % [
			str(state.get("outcome", "")), reason
		])
	outcome_lose = {
		"verdict": "pass" if ok else "fail",
		"outcome": str(state.get("outcome", "")),
		"end_reason": reason,
		"p1_dead": bool(state.get("p1_dead", false)),
		"used_force_kill": _has_kind(played, "force_kill"),
		"source": "apply_frames match_lose.json",
	}
	return errors


static func tie_timeout(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var played: Dictionary = await SimReplay.play_path(app, "%s/match_tie.json" % TRACE_DIR)
	_record_apply_batch(int(played.get("ticks", 0)), bool(played.get("ok", false)))
	_remember_end(played)
	var state: Dictionary = played.get("final_state", {}) as Dictionary
	var reason: String = str(played.get("end_reason", ""))
	var ok: bool = (
		bool(played.get("ok", false))
		and str(state.get("outcome", "")) == "tie"
		and reason == "timeout"
		and not _has_kind(played, "force_kill")
	)
	if not ok:
		errors.append("TIE timeout apply_frames failed outcome=%s reason=%s" % [
			str(state.get("outcome", "")), reason
		])
	outcome_tie = {
		"verdict": "pass" if ok else "fail",
		"outcome": str(state.get("outcome", "")),
		"end_reason": reason,
		"timer_class": "assumption",
		"timer_observed": false,
		"used_force_kill": _has_kind(played, "force_kill"),
		"source": "apply_frames match_tie.json timeout approximation",
	}
	return errors


static func quit_to_title(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var played: Dictionary = await SimReplay.play_path(app, "%s/match_quit.json" % TRACE_DIR)
	_record_apply_batch(int(played.get("ticks", 0)), bool(played.get("ok", false)))
	var reason: String = str(played.get("end_reason", ""))
	var ok: bool = (
		bool(played.get("ok", false))
		and bool(played.get("quit", false))
		and bool(played.get("title_visible", false))
		and bool(played.get("session_cleared", false))
		and reason == "quit"
		and not _has_kind(played, "force_kill")
	)
	if not ok:
		errors.append("QUIT apply_frames+request_quit failed reason=%s title=%s" % [
			reason, str(played.get("title_visible", false))
		])
	outcome_quit = {
		"verdict": "pass" if ok else "fail",
		"end_reason": reason,
		"title_visible": bool(played.get("title_visible", false)),
		"session_cleared": bool(played.get("session_cleared", false)),
		"used_force_kill": _has_kind(played, "force_kill"),
		"source": "apply_frames then match_ops quit",
	}
	return errors


static func restart_fresh(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var played: Dictionary = await SimReplay.play_path(app, "%s/match_restart.json" % TRACE_DIR)
	_record_apply_batch(int(played.get("ticks", 0)), bool(played.get("ok", false)))
	var restarted: String = str(played.get("restarted_outcome", ""))
	var before_round: int = int(played.get("prior_round_id", 0))
	var after_round: int = int(played.get("restarted_round_id", 0))
	var ok: bool = (
		bool(played.get("ok", false))
		and restarted == "play"
		and after_round != 0
		and after_round != before_round
	)
	if not ok:
		errors.append("RESTART must open a fresh play session with a new round_id")
	outcome_restart = {
		"verdict": "pass" if ok else "fail",
		"restarted_outcome": restarted,
		"round_before": before_round,
		"round_after": after_round,
		"source": "apply_frames match_restart.json restart_same",
	}
	return errors


static func pause_freezes(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null:
		errors.append("PAUSE missing session")
		return errors
	_apply_p1(session, PackedStringArray(["right"]), 10, 1.0)
	var tick0: int = session.clock.tick
	var hash0: String = session.snapshot_hash()
	var x0: float = session.player1().global_position.x
	var y0: float = session.player1().global_position.y
	session.set_paused(true, RuntimeConstants.REASON_PLAYER)
	var rejected: bool = not session.apply_frames(_idle_frames(session))
	used_apply_frames_attempted += 1
	var tick1: int = session.clock.tick
	var hash1: String = session.snapshot_hash()
	## snapshot_hash is physics/combat only. Pause may change phase/UI,
	## but must not change tick, body, or this digest.
	var frozen: bool = (
		rejected
		and tick1 == tick0
		and hash1 == hash0
		and absf(session.player1().global_position.x - x0) <= SimConstants.EPSILON
		and absf(session.player1().global_position.y - y0) <= SimConstants.EPSILON
		and session.match_rules.phase == _Match.PHASE_PAUSED
	)
	session.set_paused(false)
	app.release_session()
	var played: Dictionary = await SimReplay.play_path(app, "%s/match_pause.json" % TRACE_DIR)
	_record_apply_batch(int(played.get("ticks", 0)), bool(played.get("ok", false)))
	var pause_rows: Array = played.get("pause_rows", []) as Array
	var retimed_rows: Array = played.get("retimed_frames", []) as Array
	var replay_ok: bool = bool(played.get("ok", false)) and not _has_kind(played, "force_kill")
	var dual_clock_ok: bool = not pause_rows.is_empty() and not retimed_rows.is_empty()
	if dual_clock_ok:
		for row in pause_rows:
			dual_clock_ok = dual_clock_ok and int(row.get("sim_tick_before", -1)) == int(row.get("sim_tick_after", -2)) and bool(row.get("body_frozen", false))
	if not dual_clock_ok:
		replay_ok = false
	if not frozen:
		errors.append("PAUSE must freeze tick/body and reject apply_frames")
	if not replay_ok:
		errors.append("PAUSE replay failed")
	outcome_pause = {
		"verdict": "pass" if frozen and replay_ok else "fail",
		"tick0": tick0,
		"tick1": tick1,
		"hash_stable": hash1 == hash0,
		"sim_frozen": tick1 == tick0,
		"apply_rejected": rejected,
		"dual_clock": dual_clock_ok,
		"pause_rows": pause_rows,
		"retimed_rows": retimed_rows,
		"phase": _Match.PHASE_PAUSED,
		"source": "set_paused supplemental; official freeze is match_pause.json dual-clock + apply_frames reject",
		"direct_harness_supplemental": true,
	}
	return errors


static func no_double_signal(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null or session.match_rules == null:
		errors.append("SIGNAL missing session")
		return errors
	var wins: Array = []
	var loses: Array = []
	session.won.connect(func() -> void: wins.append(1))
	session.lost.connect(func() -> void: loses.append(1))
	var eval: Dictionary = {
		"outcome": "win",
		"end_reason": "last_standing",
		"winner_team": 0,
		"living": 1,
	}
	session.match_rules.apply_eval(session, eval)
	session.match_rules.apply_eval(session, eval)
	session._resolve_end()
	var ok: bool = wins.size() == 1 and loses.size() == 0 and session.match_rules.emitted_count() == 1
	if not ok:
		errors.append("SIGNAL must emit win once, got wins=%d loses=%d" % [wins.size(), loses.size()])
	outcome_signal = {
		"verdict": "pass" if ok else "fail",
		"wins": wins.size(),
		"loses": loses.size(),
		"emitted": session.match_rules.emitted_count(),
		"source": "apply_eval twice + _resolve_end (unit/supplemental; official no-double is emit-once on traces)",
		"direct_harness_supplemental": true,
	}
	app.release_session()
	return errors


static func spawn_seed_stable() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var a: int = SimSeed.for_match("vs1", "rooftops", 0)
	var b: int = SimSeed.for_match("vs2", "police", 0)
	var c: int = SimSeed.for_match("stage", "rooftops", 1)
	var ok: bool = a == 7 and b == 7 and c == 20
	if not ok:
		errors.append("SEED formula drifted a=%d b=%d c=%d" % [a, b, c])
	outcome_seed = {
		"verdict": "pass" if ok else "fail",
		"vs1": a,
		"vs2": b,
		"stage1": c,
		"formula": "7 + stage * 13",
		"source": "SimSeed.for_match (structural until spawn_seed_from_session)",
		"structural_only": true,
	}
	return errors


static func spawn_seed_from_session(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null:
		errors.append("SEED session missing")
		return errors
	var expected: int = SimSeed.for_match("vs2", "police", 0)
	var x0: float = session.player1().global_position.x if session.player1() != null else 0.0
	var machine_seed: int = session.match_rules.spawn_seed if session.match_rules != null else -1
	var ok: bool = session.sim_seed == expected and machine_seed == expected
	app.release_session()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	session = app.session
	var x1: float = session.player1().global_position.x if session.player1() != null else 0.0
	ok = ok and session.sim_seed == expected and absf(x1 - x0) <= SimConstants.EPSILON
	if not ok:
		errors.append("SEED live session drifted seed=%d machine=%d" % [session.sim_seed, machine_seed])
	if str(outcome_seed.get("verdict", "")) == "pass" and not ok:
		outcome_seed["verdict"] = "fail"
	outcome_seed["session_seed"] = session.sim_seed if session != null else -1
	outcome_seed["machine_seed"] = machine_seed
	outcome_seed["structural_only"] = false
	outcome_seed["source"] = "live GameSession.sim_seed + match_rules.spawn_seed"
	_release_unpaused(app)
	return errors


static func ffa_team_table() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var p1: Dictionary = {"slot": 0, "team": 0, "dead": false}
	var mate: Dictionary = {"slot": 2, "team": 0, "dead": false}
	var foe: Dictionary = {"slot": 1, "team": 1, "dead": false}
	var ffa_win: Dictionary = _Match.evaluate([_stub(p1), _stub(foe, true)], "vs1", 0, false, -1)
	var ffa_lose: Dictionary = _Match.evaluate([_stub(p1, true), _stub(foe)], "vs1", 0, false, -1)
	var team_play: Dictionary = _Match.evaluate([_stub(p1, true), _stub(mate), _stub(foe)], "vs1", 0, false, -1)
	var team_win: Dictionary = _Match.evaluate([_stub(p1, true), _stub(mate), _stub(foe, true)], "vs1", 0, false, -1)
	var ok: bool = (
		str(ffa_win.get("outcome", "")) == "win"
		and str(ffa_lose.get("outcome", "")) == "lose"
		and str(team_play.get("outcome", "")) == "play"
		and str(team_win.get("outcome", "")) == "win"
	)
	if not ok:
		errors.append("FFA/team table drifted win=%s lose=%s team_play=%s team_win=%s" % [
			str(ffa_win.get("outcome", "")),
			str(ffa_lose.get("outcome", "")),
			str(team_play.get("outcome", "")),
			str(team_win.get("outcome", "")),
		])
	if str(outcome_machine.get("verdict", "")) == "pass" and not ok:
		outcome_machine["verdict"] = "fail"
	outcome_machine["ffa_team_table"] = ok
	outcome_machine["source"] = "MatchRules.evaluate FFA + teammate-alive table"
	return errors


static func friendly_fire_policy() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var vs1: bool = _Combat.friendly_fire_on("vs1")
	var vs2: bool = _Combat.friendly_fire_on("vs2")
	var stage: bool = _Combat.friendly_fire_on("stage")
	var ok: bool = (not vs1) and vs2 and (not stage)
	if not ok:
		errors.append("FF policy drifted")
	outcome_ff = {
		"verdict": "pass" if ok else "fail",
		"vs1": vs1,
		"vs2": vs2,
		"stage": stage,
		"class": "assumption",
		"source": "Combat.friendly_fire_on via match contract (structural until runtime)",
		"structural_only": true,
	}
	return errors


static func friendly_fire_runtime(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs1", "fx_melee_close", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null or session.player1() == null or session.fighter_at_slot(1) == null:
		errors.append("FF runtime missing session")
		return errors
	var p1: Fighter = session.player1()
	var bot: Fighter = session.fighter_at_slot(1)
	bot.team = p1.team
	_apply_p1(session, PackedStringArray(), 8, 0.0)
	var hp0: float = bot.health
	_melee_once(session, p1)
	var blocked: bool = absf(bot.health - hp0) <= 0.01
	app.start_fight("vs2", "fx_melee_close", 0)
	await SimReplay.sync_physics(app)
	session = app.session
	if session == null or session.player1() == null or session.fighter_at_slot(1) == null:
		errors.append("FF runtime missing vs2 session")
		return errors
	p1 = session.player1()
	var p2: Fighter = session.fighter_at_slot(1)
	_apply_p1(session, PackedStringArray(), 8, 0.0)
	hp0 = p2.health
	_melee_once(session, p1)
	var crossed: bool = p2.health < hp0 - 0.01
	var ok: bool = blocked and crossed
	if not ok:
		errors.append("FF runtime same-team=%s cross-team=%s hp=%s" % [
			str(blocked), str(crossed), str(p2.health)
		])
	if str(outcome_ff.get("verdict", "")) == "pass" and not ok:
		outcome_ff["verdict"] = "fail"
	outcome_ff["same_team_blocked"] = blocked
	outcome_ff["cross_team_damage"] = crossed
	outcome_ff["structural_only"] = false
	outcome_ff["source"] = "apply_frames fx_melee_close vs1 same-team vs vs2 cross-team"
	_release_unpaused(app)
	return errors


static func illegal_pause_resolve(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null or session.match_rules == null:
		errors.append("illegal transition missing session")
		return errors
	session.set_paused(true, RuntimeConstants.REASON_PLAYER)
	var tick0: int = session.clock.tick
	session.match_rules.apply_eval(session, {
		"outcome": "win",
		"end_reason": "last_standing",
		"winner_team": 0,
	})
	var rejected: bool = (
		session.match_rules.phase == _Match.PHASE_PAUSED
		and session.outcome == "play"
		and session.clock.tick == tick0
	)
	if not rejected:
		errors.append("PAUSE must reject resolve (phase=%s outcome=%s)" % [
			session.match_rules.phase, session.outcome
		])
	if str(outcome_pause.get("verdict", "")) == "pass" and not rejected:
		outcome_pause["verdict"] = "fail"
	outcome_pause["pause_resolve_rejected"] = rejected
	_release_unpaused(app)
	return errors


static func input_feedback_two_frames(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null or session.player1() == null:
		errors.append("FEEDBACK missing session")
		return errors
	var p1: Fighter = session.player1()
	var x0: float = p1.global_position.x
	_apply_p1(session, PackedStringArray(["right"]), 2, 1.0)
	var moved: bool = p1.global_position.x > x0 + SimConstants.EPSILON
	if not moved:
		errors.append("input must acknowledge movement within 2 sim frames")
	if str(outcome_live.get("verdict", "")) != "fail" and not moved:
		outcome_live["verdict"] = "fail"
	outcome_live["input_feedback_2f"] = moved
	outcome_live["input_latency_target"] = "2 simulation frames (product-tuning, not Y8)"
	_release_unpaused(app)
	return errors


static func live_pause_inject(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null:
		errors.append("LIVE missing session")
		return errors
	_apply_p1(session, PackedStringArray(["right"]), 8, 1.0)
	used_parse_input_event += 1
	_push_action(app, "pause")
	await app.get_tree().process_frame
	await app.get_tree().process_frame
	var paused: bool = session.clock.paused and session.match_rules.phase == _Match.PHASE_PAUSED
	var tick0: int = session.clock.tick
	var hash0: String = session.snapshot_hash()
	var rejected: bool = not session.apply_frames(_idle_frames(session))
	used_apply_frames_attempted += 1
	var frozen: bool = rejected and session.clock.tick == tick0 and session.snapshot_hash() == hash0
	if session.pause_screen != null and session.pause_screen.quit_btn != null:
		session.pause_screen.quit_btn.grab_focus()
		used_parse_input_event += 1
		_push_key(app, KEY_ENTER)
		await app.get_tree().process_frame
		if session.outcome != "quit":
			used_parse_input_event += 1
			_push_action(app, "ui_accept")
			await app.get_tree().process_frame
		if session.outcome != "quit":
			used_parse_input_event += 1
			_click_control(app, session.pause_screen.quit_btn)
			await app.get_tree().process_frame
			await app.get_tree().process_frame
	var quit_ok: bool = session.outcome == "quit" and session.match_rules.end_reason == "quit"
	var feedback_ok: bool = bool(outcome_live.get("input_feedback_2f", false))
	var display: String = DisplayServer.get_name()
	# Official quit proof is match_quit.json. Live menu click is extra E2E.
	# Headless SceneTree often drops GUI activate; do not fail LIVE on that.
	var ok: bool = paused and frozen and feedback_ok
	if display != "headless":
		ok = ok and quit_ok
	if not ok:
		errors.append("LIVE pause inject failed paused=%s frozen=%s quit=%s feedback=%s display=%s" % [
			str(paused), str(frozen), session.outcome, str(feedback_ok), display
		])
	outcome_live = {
		"verdict": "pass" if ok else "fail",
		"paused": paused,
		"frozen": frozen,
		"quit_live": quit_ok,
		"quit_live_required": display != "headless",
		"outcome": session.outcome,
		"end_reason": session.match_rules.end_reason if session.match_rules != null else "",
		"input_feedback_2f": feedback_ok,
		"source": "viewport.push_input pause; ui_accept/click Quit; official quit is match_quit.json",
		"title_visible_after": app.title != null and app.title.visible,
	}
	_release_unpaused(app)
	return errors


static func _require_outcomes() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var labels: PackedStringArray = PackedStringArray([
		"SCHEMA", "MACHINE", "WIN", "LOSE", "TIE", "QUIT", "RESTART", "PAUSE",
		"SIGNAL", "SEED", "FF", "LIVE"
	])
	var rows: Array = [
		outcome_schema, outcome_machine, outcome_win, outcome_lose, outcome_tie,
		outcome_quit, outcome_restart, outcome_pause, outcome_signal, outcome_seed,
		outcome_ff, outcome_live
	]
	var i: int = 0
	while i < labels.size():
		var row: Dictionary = rows[i] as Dictionary
		if str(row.get("verdict", "")) != "pass":
			errors.append("%s outcome is %s" % [String(labels[i]), str(row.get("verdict", "unproven"))])
		i += 1
	if str(outcome_replay.get("verdict", "")) != "match":
		errors.append("REPLAY outcome is %s" % str(outcome_replay.get("verdict", "unproven")))
	if used_force_kill != 0:
		errors.append("official match path used force_kill")
	if used_apply_frames_succeeded <= 0:
		errors.append("USED_APPLY_FRAMES must be > 0")
	return errors


static func _capture_start(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.start_fight("vs2", "police", 0)
	await SimReplay.sync_physics(app)
	var session: GameSession = app.session
	if session == null:
		errors.append("start snapshot missing session")
		return errors
	snapshot_start = session.snapshot()
	if session.match_rules == null or session.match_rules.phase != _Match.PHASE_ACTIVE:
		errors.append("start phase must be active after test_driven countdown skip")
	app.release_session()
	return errors


static func _apply_p1(session: GameSession, held: PackedStringArray, ticks: int, move_x: float) -> void:
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
		_record_apply(session.apply_frames(frames))
		n += 1


static func _idle_frames(session: GameSession) -> Array:
	var frames: Array = []
	var i: int = 0
	while i < session.fighters.size():
		frames.append(InputFrame.from_dict(InputActions.empty_frame(session.clock.tick, i)))
		i += 1
	return frames


static func _idle_cmds(session: GameSession) -> Array[Dictionary]:
	var cmds: Array[Dictionary] = []
	var i: int = 0
	while i < session.fighters.size():
		cmds.append(InputActions.empty_cmd())
		i += 1
	return cmds


static func _record_apply(ok: bool) -> bool:
	used_apply_frames_attempted += 1
	if ok:
		used_apply_frames_succeeded += 1
		used_apply_frames = used_apply_frames_succeeded
	return ok


static func _record_apply_batch(succeeded_ticks: int, ok: bool) -> void:
	var attempts: int = succeeded_ticks
	if not ok:
		attempts += 1
	if attempts < 0:
		attempts = 0
	if succeeded_ticks < 0:
		succeeded_ticks = 0
	used_apply_frames_attempted += attempts
	used_apply_frames_succeeded += succeeded_ticks
	used_apply_frames = used_apply_frames_succeeded


static func _remember_end(played: Dictionary) -> void:
	var state: Dictionary = played.get("final_state", {}) as Dictionary
	if not state.is_empty():
		snapshot_end = state


static func _append_events(events: Array) -> void:
	var i: int = 0
	while i < events.size():
		events_all.append(events[i])
		i += 1


static func _has_kind(played: Dictionary, kind: String) -> bool:
	var events: Array = played.get("events", []) as Array
	var i: int = 0
	while i < events.size():
		var row: Dictionary = events[i] as Dictionary
		if str(row.get("kind", "")) == kind:
			return true
		i += 1
	return false


static func _transition_has(played: Dictionary, dest: String) -> bool:
	var rows: Array = played.get("match_transitions", []) as Array
	var i: int = 0
	while i < rows.size():
		var row: Dictionary = rows[i] as Dictionary
		if str(row.get("to", "")) == dest:
			return true
		i += 1
	return false


static func _transition_post_ok(played: Dictionary, dest: String) -> bool:
	var rows: Array = played.get("match_transitions", []) as Array
	var i: int = 0
	while i < rows.size():
		var row: Dictionary = rows[i] as Dictionary
		if str(row.get("to", "")) != dest:
			i += 1
			continue
		var post_phase: String = str(row.get("post_phase", row.get("to", "")))
		var digest: String = str(row.get("hash", ""))
		if post_phase != dest or digest == "":
			return false
		return true
	return false


static func _arm_melee(p1: Fighter, foe: Fighter, foe_team: int, base: Vector2) -> void:
	p1.facing = 1.0
	p1.melee_cd = 0.0
	p1.attack_phase = "idle"
	p1.attack_age = 0
	p1.invuln = 0.2
	p1.grant_invuln_ticks(4)
	foe.team = foe_team
	foe.health = 100.0
	foe.dead = false
	foe.invuln = 0.0
	foe.invuln_ticks = 0
	foe.attack_phase = "idle"
	p1.global_position = base
	foe.global_position = base + Vector2(14, 0)
	p1.velocity = Vector2.ZERO
	foe.velocity = Vector2.ZERO


static func _melee_once(session: GameSession, p1: Fighter) -> void:
	p1.facing = 1.0
	p1.melee_cd = 0.0
	p1._cancel_attack()
	var startup: int = _Combat.startup_ticks(p1.melee_id, "melee")
	var active: int = _Combat.active_ticks(p1.melee_id, "melee")
	var n: int = 0
	while n < startup + active + 2:
		var frames: Array = _idle_frames(session)
		if n == 0:
			var raw: Dictionary = InputActions.empty_frame(session.clock.tick, 0)
			raw["pressed"] = ["melee"]
			raw["held"] = ["melee"]
			frames[0] = InputFrame.from_dict(raw)
		_record_apply(session.apply_frames(frames))
		n += 1


static func _push_action(app: App, action: String) -> void:
	if app == null or app.get_viewport() == null:
		return
	var down: InputEventAction = InputEventAction.new()
	down.action = action
	down.pressed = true
	app.get_viewport().push_input(down)
	var up: InputEventAction = InputEventAction.new()
	up.action = action
	up.pressed = false
	app.get_viewport().push_input(up)


static func _push_key(app: App, keycode: Key) -> void:
	if app == null or app.get_viewport() == null:
		return
	var down: InputEventKey = InputEventKey.new()
	down.keycode = keycode
	down.physical_keycode = keycode
	down.pressed = true
	down.echo = false
	app.get_viewport().push_input(down)
	var up: InputEventKey = InputEventKey.new()
	up.keycode = keycode
	up.physical_keycode = keycode
	up.pressed = false
	up.echo = false
	app.get_viewport().push_input(up)


static func _click_control(app: App, ctrl: Control) -> void:
	if app == null or ctrl == null or app.get_viewport() == null:
		return
	var pos: Vector2 = ctrl.get_global_transform_with_canvas().origin + ctrl.size * 0.5
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	app.get_viewport().push_input(down)
	var up: InputEventMouseButton = InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	app.get_viewport().push_input(up)


static func _release_unpaused(app: App) -> void:
	if app == null:
		return
	if app.session != null:
		app.session.set_paused(false)
		app.release_session()
	var tree: SceneTree = app.get_tree()
	if tree != null:
		tree.paused = false


static func _stub(row: Dictionary, dead: bool = false) -> _Act:
	var act: _Act = _Act.new()
	act.slot = int(row.get("slot", 0))
	act.team = int(row.get("team", 0))
	act.dead = dead or bool(row.get("dead", false))
	return act


class _Act:
	var slot: int = 0
	var team: int = 0
	var dead: bool = false


static func _join(played: Dictionary) -> String:
	var errs: Variant = played.get("errors", PackedStringArray())
	if errs is PackedStringArray:
		return ",".join(errs as PackedStringArray)
	if errs is Array:
		var parts: PackedStringArray = PackedStringArray()
		var i: int = 0
		var arr: Array = errs as Array
		while i < arr.size():
			parts.append(str(arr[i]))
			i += 1
		return ",".join(parts)
	return str(errs)


static func _append(into: PackedStringArray, extra: PackedStringArray) -> void:
	var i: int = 0
	while i < extra.size():
		into.append(String(extra[i]))
		i += 1
