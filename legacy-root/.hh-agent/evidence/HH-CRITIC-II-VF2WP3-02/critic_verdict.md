# Hostile Critic II — VF2-WP3 leftover-0

TICK=yes (VF2-WP3 only). Plan not ticked. Product not edited. No commit. VF2-WP4 not started.

Independent leftover-0. Model: cursor-grok-4.6-xhigh-fast.

## Gate / freeze

- HEAD `eb6973f` (`eb6973f49ccc32fdd6fdda803bef9ee3518771f0`)
- `CORRECTION_GATE_VF2_WP2=CLEARED`; VF2-WP2 `[x]`; VF2-WP3 `[ ]`; total 9/50; `CURRENT_VALID_WP=VF2-WP3`
- Parent 20-8 unchanged: R9-WP4 `[ ]`, 59/60, G6 `[ ]`, GX `[ ]`. No git diff on either plan.

## Reproduced

- source_tree_sha256 `7b923799c3aad6cf4cb55a51bd80f40f8a91aca130b584235f22eb7880aa0305` MATCH (per-file + tree)
- Godot pin SHA `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a` MATCH
- `check_sprint.py` EXIT 0
- headless `run_sprint.gd` EXIT 0 leftover 0 — TAP/STAMINA/ROLL/INVULN/DUP/LIVE pass, REPLAY match, APPLY 717/718
- windowed `run_sprint.gd` EXIT 0 leftover 0 — DISPLAY=Windows, screenshot 1280x720, same banners
- headless `run_all.gd` EXIT 0 leftover 0 — `HH_VF_SPRINT TAP=pass … APPLY=717/718 status=proven`
- leftover Godot on product `--path` = 0 after each run

## Hunts

1. Hash recompute: MATCH. Review copies byte-match `.evidence/.../packed/`.
2. Official leftover-0: PASS ×4.
3. `-01` exists as voided leftover pack; official scripts/packer use unique `-02`. §18.3 fields present in `-02` `run.json` (WP, base, Godot hash, OS, seed, traces, command_id, start/end, verdict).
4. Banners copy `SprintCases.outcome_*` (`TAP_SOURCE=outcome_tap` …). Not fail-substring inferred.
5. Roll is not velocity-only: pose `roll`, AABB shrink/swap, SFX `last_id=roll`, HUD `ROLL`, extinguish hook, invuln 0.20. Window HUD shows `ST 74 ROLL`.
6. DUP: 10 extra presses keep `roll_seq==1` / one `roll_start`. INVULN: Bullet inside window HP 80, outside 55.
7. Sprint/roll stay `assumption` (not `observed`). Plan not ticked. Parent not mutated.

## Residual nits (not TICK=no)

- `events.jsonl` is last-session only (4 lines), not a full-run ledger.
- `metrics.json` RSS is a hint string, not measured process RSS.
- `outcome_roll` does not assert a live VFX node (code does spawn `vfx_roll` / flash).
- Voided `-01` pack still sits under `docs/evidence/`.

## Honesty

- 60 Hz: `ledger:RL-SIM-FIXED-60` assumption, not observed Y8 clock.
- Sprint: `ledger:RL-MOVE-SPRINT` assumption, not observed.
- Roll: `ledger:RL-MOVE-ROLL` assumption, not observed.
- Hold-to-aim: `ledger:RL-CTRL-HOLD-AIM` assumption.
- Dive/kick: `ledger:RL-MOVE-ROLL-DIVE` unavailable.
- Not Y8 parity. Not V0. No critic tick of the plan.
