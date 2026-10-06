# Hostile Critic II — VF6-WP2 remint `-02`

TICK=yes

Independent leftover-0 iso: `.hh-agent/critic-vf6wp2-ii/iso`
Console twin. Product not edited. Plan checkbox not ticked. VF6-WP3 not started.

## Independent leftover-0

- Recomputed freeze `eaddfebe0fb320a2bd64a2df473dcccdd7fc42fcd13d3672bcf99a4699b0f5d6` MATCH (116/116, no drift).
- Isolated windowed `Godot_v4.7.1-stable_win64_console.exe --path iso --script res://tests/run_vs_flow.gd`
- Host `WaitForExit` **0** in **26.3s** (not -1). Hung=false. Leftover on this iso **0**.
- Banner `FINISHED=1 PROCESS_EXIT=0`. No ObjectDB/AudioStream/WARNING/ERROR.
- Godot pin sha256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` MATCH.
- HONESTY `P2_COVERAGE=live_local BOT_COVERAGE=smoke NOT_AI=1 NOT_Y8_PARITY=1 SURVIVAL_SHIPPED=0 STAGE_LIFECYCLE=0`
- Critic stills (6 png, 1280x720) written under `window-ev/screens/`. Official packed dir has **none**.

## Hunts

1. Freeze before official Godot, hash live==claim: **pass**
2. Isolated leftover-0 windowed console `run_vs_flow.gd` <4 min exit 0 leftover 0: **pass**
3. Title→Start counted from timeline/outcomes (not banner): vs1=2a/0.481s vs2=2a/0.252s via title VS button then lobby Start. Rematch=1a/0.095s from result Rematch. No teleport, no `start_fight` skip of title: **pass**
4. P1 KEY_RIGHT moves P1 only; P2 KEY_A moves P2 only; melee KEY_N/KEY_1 isolated: **pass**
5. Die/resolve is live rooftops pit `death_cause=pit` / `p1_down` at tick 62. `used_force_kill=0` `used_teleport=0`. Not editor click: **pass**
6. Plan VF6-WP2 still `[ ]`. Survival unshipped. VF7 art not imported. No ObjectDB. Parent 20-8 still R9-WP4 `[ ]` 59/60 G6 `[ ]`: **pass**

## Residual nits (not TICK=no)

- Official `docs/evidence/VF6WP2-20260901-ASIA-SAIGON-02/` lists 6 stills in `run.json` but the folder has no `screens/`. V-A18 of the packed dir is thin; leftover-0 recaptured the stills. Coordinator must not treat official stills as present.
- Official `run_partial.json` stamps `map_id=police` while resolve snapshot/events are `rooftops` pit. Banner `MAP=police` is the harness constant, not the death map.
- Combat on police did not finish the round. Harness falls back to title→cycle rooftops→hold KEY_RIGHT. Live pit, but not a combat KO.
- First-run/rematch official path is viewport button clicks (`push_input` mouse, ENTER fallback), not keyboard-only. Play/leak use `parse_input_event`.
- `official_run_all.log` has no `PROCESS_EXIT`. Critic II did not remint `run_all.gd` (packed claim 1515.3s / exit 0).
- Title shows a Stage button that calls `start_fight("stage")`. Survival is not shipped. Stage lifecycle is a sneak of VF6-WP3, labeled `STAGE_LIFECYCLE=0`.
- HUD still prints HP/ST/G3/x0 debug tokens. Art remains VF7.
- Feedback `frames=2` is the hold length, not a measured first-motion frame. P1 did move after those 2 applies.
- Freeze closure is 116 script/data files; assets/png/wav are outside the hash.

HEAD `2a93dfa`. Title **Vault Fighters**. 30/50. VF6 1/5. CURRENT_VALID_WP=VF6-WP2.
