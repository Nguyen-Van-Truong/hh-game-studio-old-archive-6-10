class_name StageCases
extends RefCounted

## VF6-WP3 stage campaign. Official proof is title clicks plus
## apply_frames Close Clinch KOs. No teleport. No force_kill.
## Bots stay smoke. Survival unshipped. Tiers are approximation.

const _Stage: GDScript = preload("res://src/sim/stage.gd")
const RUN_ID := "VF6WP3-20260901-ASIA-SAIGON-01"

static var used_step_fixed: int = 0
static var used_apply_frames: int = 0
static var used_apply_frames_attempted: int = 0
static var used_apply_frames_succeeded: int = 0
static var used_parse_input_event: int = 0
static var used_action_press: int = 0
static var used_force_kill: int = 0
static var used_teleport: int = 0
static var outcome_schema: Dictionary = {}
static var outcome_load: Dictionary = {}
static var outcome_advance: Dictionary = {}
static var outcome_loss: Dictionary = {}
static var outcome_hash: Dictionary = {}
static var outcome_continue: Dictionary = {}
static var outcome_reset: Dictionary = {}
static var outcome_live: Dictionary = {}
static var still_paths: Dictionary = {}
static var timeline: Array = []
static var snapshot_start: Dictionary = {}
static var snapshot_end: Dictionary = {}
static var events_all: Array = []
static var load_rows: Array = []


static func run_all(app: App) -> PackedStringArray:
	used_step_fixed = 0
	used_apply_frames = 0
	used_apply_frames_attempted = 0
	used_apply_frames_succeeded = 0
	used_parse_input_event = 0
	used_action_press = 0
	used_force_kill = 0
	used_teleport = 0
	outcome_schema = {"verdict": "unproven"}
	outcome_load = {"verdict": "unproven"}
	outcome_advance = {"verdict": "unproven"}
	outcome_loss = {"verdict": "unproven"}
	outcome_hash = {"verdict": "unproven"}
	outcome_continue = {"verdict": "unproven"}
	outcome_reset = {"verdict": "unproven"}
	outcome_live = {"verdict": "unproven"}
	still_paths = {}
	timeline = []
	snapshot_start = {}
	snapshot_end = {}
	events_all = []
	load_rows = []
	_Stage.reset_progress()
	var errors: PackedStringArray = PackedStringArray()
	_append(errors, schema_contract())
	print("HH_VF_STAGE STEP=hash")
	_append(errors, reward_hash_stable())
	print("HH_VF_STAGE STEP=load")
	_append(errors, await load_roster(app))
	print("HH_VF_STAGE STEP=title_loss")
	_append(errors, await title_and_loss(app))
	print("HH_VF_STAGE STEP=advance")
	_append(errors, await win_advances(app))
	print("HH_VF_STAGE STEP=continue_reset")
	_append(errors, await continue_and_reset(app))
	_append(errors, _require_outcomes())
	return errors


static func schema_contract() -> PackedStringArray:
	var errors: PackedStringArray = _Stage.validate()
	var payload: Dictionary = _Stage.data()
	if bool(payload.get("survival_shipped", false)):
		errors.append("Survival must stay unshipped")
	if str(payload.get("order_class", "")) != "approximation":
		errors.append("stage order must stay approximation")
	outcome_schema = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"source": "data/sim/stage.json",
		"order_class": str(payload.get("order_class", "")),
		"tier_class": str(payload.get("difficulty_class", "")),
		"y8_order_observed": bool(payload.get("y8_order_observed", true)),
	}
	return errors


static func reward_hash_stable() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	_Stage.reset_progress()
	var first: Dictionary = _Stage.record_win(0)
	var h1: String = str(first.get("reward_hash", ""))
	var again: Dictionary = _Stage.record_win(0)
	var h1b: String = str(again.get("reward_hash", ""))
	if h1 == "" or h1 != h1b:
		errors.append("HASH first-win must be stable on duplicate award")
	if int(again.get("score", 0)) != int(first.get("score", 0)):
		errors.append("HASH duplicate win must not add score")
	if int(again.get("current_index", -1)) != 1:
		errors.append("HASH first win must checkpoint index 1")
	var second: Dictionary = _Stage.record_win(1)
	var h2: String = str(second.get("reward_hash", ""))
	if h2 == "" or h2 == h1:
		errors.append("HASH second distinct win must change hash")
	_Stage.reset_progress()
	var replay: Dictionary = _Stage.record_win(0)
	_Stage.record_win(1)
	var replay2: Dictionary = _Stage.load_or_empty()
	if str(replay.get("reward_hash", "")) != h1:
		errors.append("HASH replay of first win must match")
	if str(replay2.get("reward_hash", "")) != h2:
		errors.append("HASH replay of two-win sequence must match")
	outcome_hash = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"hash_win0": h1,
		"hash_win0_dup": h1b,
		"hash_win1": h2,
		"source": "StageRules.record_win idempotent + sequence replay",
	}
	_Stage.reset_progress()
	return errors


static func load_roster(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var ids: PackedStringArray = _Stage.arena_ids()
	var i: int = 0
	var ok: bool = ids.size() == 4
	while i < ids.size():
		var mid: String = String(ids[i])
		app.start_fight("stage", mid, i)
		await SimReplay.sync_physics(app)
		var session: GameSession = app.session
		var bots: int = 0
		if session != null:
			bots = session.live_bot_count()
		var want_bots: int = _Stage.bot_count(i)
		var row: Dictionary = {
			"index": i,
			"map_id": mid,
			"loaded": session != null and session.map_id == mid,
			"bots": bots,
			"want_bots": want_bots,
			"tier": _Stage.tier_id(i),
			"tier_class": "approximation",
		}
		load_rows.append(row)
		if session == null or session.map_id != mid or session.mode != "stage":
			errors.append("LOAD stage %d map %s missing" % [i, mid])
			ok = false
		if bots != want_bots:
			errors.append("LOAD stage %d bots=%d want=%d" % [i, bots, want_bots])
			ok = false
		i += 1
	if DisplayServer.get_name() != "headless" and still_paths.get("load", "") == "":
		still_paths["load"] = await _capture_still(app, "stage_load")
	outcome_load = {
		"verdict": "pass" if ok else "fail",
		"rows": load_rows,
		"source": "start_fight catalog maps; live_bot_count; no force_kill",
	}
	return errors


static func title_and_loss(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	_Stage.reset_progress()
	app.restart_to_title()
	await _ui_frames(app)
	still_paths["title"] = await _capture_still(app, "stage_title")
	_append(errors, await _title_start_stage(app))
	var session: GameSession = app.session
	if session == null or session.map_id != "rooftops" or session.stage_index != 0:
		errors.append("TITLE Stage must load rooftops index 0")
		outcome_loss = {"verdict": "fail", "source": "title Stage missed rooftops"}
		return errors
	still_paths["fight"] = await _capture_still(app, "stage_fight")
	if snapshot_start.is_empty() and session != null:
		snapshot_start = session.snapshot()
	await _typed_hold_keys(app, [KEY_RIGHT], 160)
	await _ui_frames(app)
	var lost: bool = (
		session != null
		and session.outcome == "lose"
		and app.lose_screen != null
		and app.lose_screen.visible
	)
	if not lost:
		errors.append("LOSS rooftops pit walk did not lose")
	var hash_before: String = str(_Stage.load_or_empty().get("reward_hash", ""))
	var idx_before: int = app.stage_index
	still_paths["lose"] = await _capture_still(app, "stage_lose")
	if app.lose_screen != null and app.lose_screen.rematch_btn != null:
		await _activate_button(app, app.lose_screen.rematch_btn, "rematch")
		await SimReplay.sync_physics(app)
	session = app.session
	var stayed: bool = (
		session != null
		and session.mode == "stage"
		and session.map_id == "rooftops"
		and session.stage_index == 0
		and idx_before == 0
		and session.outcome == "play"
	)
	var hash_after: String = str(_Stage.load_or_empty().get("reward_hash", ""))
	if not stayed:
		errors.append(
			"LOSS rematch skipped/duped map=%s idx=%d"
			% [str(session.map_id if session != null else ""), app.stage_index]
		)
	if hash_after != hash_before:
		errors.append("LOSS rematch must not change reward hash")
	outcome_loss = {
		"verdict": "pass" if lost and stayed and hash_after == hash_before else "fail",
		"lost": lost,
		"stayed_map": session.map_id if session != null else "",
		"stayed_index": app.stage_index,
		"hash_before": hash_before,
		"hash_after": hash_after,
		"source": "title Stage rooftops + KEY_RIGHT pit + Rematch stays index 0",
	}
	return errors


static func win_advances(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	_Stage.reset_progress()
	_append(errors, await _title_start_stage(app))
	if app.session == null or app.session.map_id != "rooftops":
		errors.append("ADVANCE title Stage must start rooftops")
		outcome_advance = {"verdict": "fail"}
		return errors
	await _clinch_win(app, 0)
	await _wait_advance(app)
	var after0: GameSession = app.session
	var after0_map: String = after0.map_id if after0 != null else ""
	var after0_idx: int = after0.stage_index if after0 != null else -1
	var after0_bots: int = after0.live_bot_count() if after0 != null else -1
	var progress0: Dictionary = _Stage.load_or_empty()
	var ok0: bool = (
		after0 != null
		and after0_map == "storage"
		and after0_idx == 1
		and after0_bots == _Stage.bot_count(1)
		and int(progress0.get("current_index", -1)) == 1
		and int(progress0.get("score", 0)) == _Stage.score_for(0)
	)
	if not ok0:
		errors.append(
			"ADVANCE win0 map=%s idx=%d bots=%s score=%s"
			% [
				after0_map,
				after0_idx,
				str(after0_bots),
				str(progress0.get("score", -1)),
			]
		)
	still_paths["advance"] = await _capture_still(app, "stage_advance")
	var h0: String = str(progress0.get("reward_hash", ""))
	await _clinch_win(app, 1)
	await _wait_advance(app)
	var after1: GameSession = app.session
	var after1_map: String = after1.map_id if after1 != null else ""
	var after1_idx: int = after1.stage_index if after1 != null else -1
	var progress1: Dictionary = _Stage.load_or_empty()
	var ok1: bool = (
		after1 != null
		and after1_map == "police"
		and after1_idx == 2
		and int(progress1.get("current_index", -1)) == 2
		and str(progress1.get("reward_hash", "")) != h0
	)
	if not ok1:
		errors.append(
			"ADVANCE win1 map=%s idx=%d hash_changed=%s"
			% [
				after1_map,
				after1_idx,
				str(str(progress1.get("reward_hash", "")) != h0),
			]
		)
	var h1: String = str(progress1.get("reward_hash", ""))
	if after1 != null and after1.match_rules != null:
		after1.match_rules.apply_eval(after1, {
			"outcome": "lose",
			"end_reason": "p1_down",
			"winner_team": 1,
		})
	await _ui_frames(app)
	var hash_mid: String = str(_Stage.load_or_empty().get("reward_hash", ""))
	if app.lose_screen != null and app.lose_screen.visible and app.lose_screen.rematch_btn != null:
		await _activate_button(app, app.lose_screen.rematch_btn, "rematch")
		await SimReplay.sync_physics(app)
	var rematch: GameSession = app.session
	var stayed: bool = (
		rematch != null
		and rematch.map_id == "police"
		and rematch.stage_index == 2
		and rematch.outcome == "play"
		and hash_mid == h1
	)
	if not stayed:
		errors.append(
			"ADVANCE mid-loss rematch map=%s idx=%d"
			% [str(rematch.map_id if rematch != null else ""), app.stage_index]
		)
	if after1 != null and after1.ledger != null:
		_append_events(after1.ledger.to_array())
	if rematch != null:
		snapshot_end = rematch.snapshot()
	var rematch_map: String = rematch.map_id if rematch != null else ""
	outcome_advance = {
		"verdict": "pass" if ok0 and ok1 and stayed else "fail",
		"after_win0_map": after0_map,
		"after_win1_map": after1_map,
		"rematch_map": rematch_map,
		"hash_win0": h0,
		"hash_win1": h1,
		"hash_after_loss": hash_mid,
		"source": "title Stage + Close Clinch apply_frames KO; auto-advance catalog; rematch stays",
	}
	if str(outcome_hash.get("verdict", "")) != "fail" and h0 != "" and h1 != "" and hash_mid == h1:
		outcome_hash["live_hash_win0"] = h0
		outcome_hash["live_hash_win1"] = h1
		outcome_hash["live_hash_after_loss"] = hash_mid
	return errors


static func continue_and_reset(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var before: Dictionary = _Stage.load_or_empty()
	app.restart_to_title()
	await _ui_frames(app)
	if app.title != null:
		app.title.refresh_stage_caption()
	still_paths["continue_title"] = await _capture_still(app, "stage_continue")
	_append(errors, await _title_start_stage(app))
	var session: GameSession = app.session
	var continued: bool = (
		session != null
		and session.map_id == _Stage.map_at(int(before.get("current_index", 0)))
		and session.stage_index == int(before.get("current_index", 0))
		and session.map_id != "rooftops"
	)
	if not continued:
		errors.append(
			"CONTINUE title loaded %s idx=%d want %s"
			% [
				str(session.map_id if session != null else ""),
				app.stage_index,
				_Stage.map_at(int(before.get("current_index", 0))),
			]
		)
	outcome_continue = {
		"verdict": "pass" if continued else "fail",
		"map_id": session.map_id if session != null else "",
		"stage_index": app.stage_index,
		"source": "title Continue Stage loads checkpoint, not rooftops rematch",
	}
	app.restart_to_title()
	await _ui_frames(app)
	if app.title == null or app.title.reset_stage_btn == null:
		errors.append("RESET missing Reset Stage")
		outcome_reset = {"verdict": "fail"}
		return errors
	await _activate_button(app, app.title.reset_stage_btn, "reset")
	var wiped: Dictionary = _Stage.load_or_empty()
	var reset_ok: bool = (
		int(wiped.get("current_index", -1)) == 0
		and int(wiped.get("score", -1)) == 0
		and _array(wiped.get("awarded", [])).is_empty()
	)
	_append(errors, await _title_start_stage(app))
	session = app.session
	var fresh: bool = session != null and session.map_id == "rooftops" and session.stage_index == 0
	if not reset_ok or not fresh:
		errors.append("RESET did not wipe and restart rooftops")
	still_paths["reset"] = await _capture_still(app, "stage_reset")
	still_paths["title_after"] = await _capture_still(app, "stage_title_after")
	outcome_reset = {
		"verdict": "pass" if reset_ok and fresh else "fail",
		"score": int(wiped.get("score", -1)),
		"index": int(wiped.get("current_index", -1)),
		"map_id": session.map_id if session != null else "",
		"source": "title Reset Stage wipe + Stage starts rooftops",
	}
	outcome_live = {
		"verdict": "pass" if errors.is_empty() else "fail",
		"title_visible_after": app.title != null,
		"source": "window/menu Stage/Reset clicks + apply_frames Close Clinch",
	}
	return errors


static func _title_start_stage(app: App) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	app.restart_to_title()
	await _ui_frames(app)
	if app.title == null or app.title.stage_btn == null:
		errors.append("title missing Stage")
		return errors
	await _activate_button(app, app.title.stage_btn, "fight")
	await SimReplay.sync_physics(app)
	if app.session == null or app.session.mode != "stage":
		errors.append("title Stage missed session")
	return errors


static func _clinch_win(app: App, index: int) -> void:
	app.start_fight("stage", "fx_melee_close", index)
	await SimReplay.sync_physics(app)
	_sanitize_input(app)
	await _typed_idle(app, 4)
	var session: GameSession = app.session
	if session == null or session.player1() == null:
		return
	var p1: Fighter = session.player1()
	var cycle: int = 0
	while cycle < 64 and session != null and session.outcome == "play":
		var foe: Fighter = _first_living_foe(session)
		if foe == null:
			await _typed_idle(app, 4)
			cycle += 1
			continue
		var face: Key = KEY_RIGHT
		if foe.global_position.x < p1.global_position.x:
			face = KEY_LEFT
		if _horiz_sep(p1, foe) > 20.0:
			await _typed_hold_keys(app, [face], 6)
		await _typed_hold_keys(app, [face, KEY_N], 8)
		await _typed_idle(app, 8)
		cycle += 1
	await _ui_frames(app)


static func _wait_advance(app: App) -> void:
	var n: int = 0
	while n < 8:
		await _ui_frames(app)
		if app.get_tree() != null:
			await app.get_tree().process_frame
		n += 1
	await SimReplay.sync_physics(app)


static func _first_living_foe(session: GameSession) -> Fighter:
	if session == null:
		return null
	var p1: Fighter = session.player1()
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		i += 1
		if f == null or f == p1 or f.dead:
			continue
		return f
	return null


static func _require_outcomes() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var labels: PackedStringArray = PackedStringArray([
		"SCHEMA", "LOAD", "ADVANCE", "LOSS", "HASH", "CONTINUE", "RESET", "LIVE"
	])
	var rows: Array = [
		outcome_schema, outcome_load, outcome_advance, outcome_loss,
		outcome_hash, outcome_continue, outcome_reset, outcome_live
	]
	var i: int = 0
	while i < labels.size():
		var row: Dictionary = rows[i] as Dictionary
		if str(row.get("verdict", "")) != "pass":
			errors.append("%s outcome is %s" % [String(labels[i]), str(row.get("verdict", "unproven"))])
		i += 1
	if used_force_kill != 0:
		errors.append("official stage used force_kill")
	if used_teleport != 0:
		errors.append("official stage used teleport")
	if used_step_fixed != 0:
		errors.append("official stage used step_fixed")
	return errors


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
	if kind == "reset":
		return str(int(_Stage.load_or_empty().get("score", 0)))
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


static func _horiz_sep(a: Fighter, b: Fighter) -> float:
	if a == null or b == null:
		return 999.0
	return absf(a.global_position.x - b.global_position.x)


static func _typed_hold_keys(app: App, keys: Array, ticks: int) -> void:
	if app == null or app.session == null or ticks <= 0 or keys.is_empty():
		return
	var vp: Viewport = app.get_viewport()
	var i: int = 0
	while i < keys.size():
		InputInjector.inject_key(keys[i] as Key, true, vp)
		used_parse_input_event += 1
		i += 1
	var n: int = 0
	while n < ticks and app.session != null and app.session.outcome == "play":
		_apply_live(app.session)
		n += 1
	i = 0
	while i < keys.size():
		InputInjector.inject_key(keys[i] as Key, false, vp)
		used_parse_input_event += 1
		i += 1
	if app.session != null and app.session.outcome == "play":
		_apply_live(app.session)
	InputActions.reset_edges()


static func _typed_idle(app: App, ticks: int) -> void:
	var n: int = 0
	while n < ticks and app != null and app.session != null and app.session.outcome == "play":
		_apply_live(app.session)
		n += 1


static func _apply_live(session: GameSession) -> void:
	if session == null:
		return
	var frames: Array = []
	var i: int = 0
	while i < session.fighters.size():
		var f: Fighter = session.fighters[i]
		if f != null and f.is_human:
			frames.append(InputActions.read_player_frame(f.slot, session.clock.tick))
		else:
			frames.append(InputFrame.from_dict(InputActions.empty_frame(session.clock.tick, i)))
		i += 1
	used_apply_frames_attempted += 1
	if session.apply_frames(frames):
		used_apply_frames_succeeded += 1
		used_apply_frames += 1


static func _ui_frames(app: App) -> void:
	if app == null or app.get_tree() == null:
		return
	var tree: SceneTree = app.get_tree()
	await tree.process_frame
	await tree.process_frame


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
	print("HH_VF_STAGE SCREENSHOT_%s err=%d path=%s" % [stem, int(err), shot])
	return shot


static func _array(value: Variant) -> Array:
	if value is Array:
		return value as Array
	return []


static func _append_events(rows: Array) -> void:
	var i: int = 0
	while i < rows.size():
		events_all.append(rows[i])
		i += 1


static func _append(into: PackedStringArray, extra: PackedStringArray) -> void:
	var i: int = 0
	while i < extra.size():
		into.append(String(extra[i]))
		i += 1
