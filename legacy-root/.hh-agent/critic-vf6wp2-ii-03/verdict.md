# Hostile Critic II — VF6-WP2 remint `-03`

TICK=yes

Independent leftover-0 iso: `.hh-agent/critic-vf6wp2-ii-03/iso`
Console twin. Product not edited. Plan checkbox not ticked. VF6-WP3 not started.

RUN_ID=VF6WP2-20260901-ASIA-SAIGON-03
COMMAND_ID=cmd.vf6-wp2.vs-flow.3
SOURCE=81c44f5bbe9a4c16c3fdd8599147309edc550228bdec79ed00a5fddcb8d3f55b
HEAD=2a93dfa
TITLE=Vault Fighters
29-8 VF6-WP2 still [ ]. VF6 1/5. 30/50. Parent 59/60.

## Independent leftover-0

- Recomputed freeze `81c44f5bbe9a4c16c3fdd8599147309edc550228bdec79ed00a5fddcb8d3f55b` MATCH (116/116, no drift). Freeze `frozen_at=2026-09-01T19:31:23+07:00` is before official window `STARTED_AT=19:31:39`.
- Godot pin sha256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` MATCH. Console twin `Godot_v4.7.1-stable_win64_console.exe`.
- Isolated windowed `--path iso --script res://tests/run_vs_flow.gd`
- Host `WaitForExit` **0** in **7.1s** (not -1). Hung=false. Leftover on this iso **0** before and after. No leftover Godot after.
- Banner `FINISHED=1 PROCESS_EXIT=0`. Stderr empty. No ObjectDB/AudioStream/WARNING/ERROR.
- PLAY_TRACE (not banner-only): `map=fx_melee_close` `p1_moved=true` `p2_moved=true` `p1_attacked=true` `p2_attacked=true` `hit=true` `outcome=win` `death_cause=damage` `end_reason=last_standing` `hp=100.0/0.0` `PIT_FALLBACK=0`
- Ledger death event `cause=damage` slot=1 tick=587. Zero pit events. Snapshot P2 `dead=1` `death_cause=damage` `hp=0` `y=36000` (same floor as P1, not a pit fall). P2 `attack_seq=1`. P1 `attack_seq=21`.
- Both slots landed at least one melee hit in the concatenated ledger (attacker 1 tick 15; attacker 0 many). `-02` rooftops KEY_RIGHT pit / P2 idle HP 100 did not reproduce.
- HONESTY `P2_COVERAGE=live_local BOT_COVERAGE=smoke NOT_AI=1 NOT_Y8_PARITY=1 SURVIVAL_SHIPPED=0 STAGE_LIFECYCLE=0`
- Critic stills (6 png, 1280x720, non-zero) under `window-ev/screens/`. Official packed `docs/evidence/VF6WP2-20260901-ASIA-SAIGON-03/screens/` also has the same six names on disk.

## Hunts

1. Freeze before official Godot, live hash == claim == freeze: **pass**
2. Isolated leftover-0 windowed console `run_vs_flow.gd` <4 min exit 0 leftover 0: **pass** (7.1s)
3. Same encounter both moved+attacked; death ≠ pit: **pass** (Close Clinch / `fx_melee_close`, `death_cause=damage`, `PIT_FALLBACK=0`)
4. P1/P2 leak + 2-tap start / 1-tap rematch: **pass** (vs1=2a/0.309s vs2=2a/0.249s rematch=1a/0.067s; owner ≤3/30s and ≤2/5s hold). Leak KEY_RIGHT/KEY_A/KEY_N/KEY_1 isolated.
5. All listed stills exist on disk. Plan `[ ]`: **pass**

V-A18: official `run.json` has `packed_at`, `run_id`, `command_id`, `source_tree_sha256`, `godot_sha256`; window log has `STARTED_AT`/`ENDED_AT`; window evidence has `events.jsonl` + snapshots. Repro is the console command in leftover_proof (`--path … --script res://tests/run_vs_flow.gd`), not a dedicated `repro` field.

## Residual nits (not TICK=no)

- Play KO path is `start_fight("vs2","fx_melee_close")` after first_run already proved title→Start. Not teleport/force_kill, but the damage death is not the Skyline Relay lobby Start still.
- `used_pit_fallback` is authored `0` in outcomes; the live proof is `death_cause=damage` + no pit events, not that counter.
- Fight still is full-HP Close Clinch clinch; resolve is the result overlay (`Last standing`, winner team 0).
- Window P1 ends HP 100 after a logged P2 hit at tick 15 (events.jsonl concatenates sessions). Headless official was 90.66/0. Does not restore pit fallback.
- Packer omits an explicit `repro` string. HUD still prints HP/ST debug tokens. Stage button remains; Survival unshipped. Art is VF7. Bots stay smoke.

Product not edited. Plan not ticked. VF6-WP3 not started. Y8 not ripped.
