# Hostile Critic II — VF2-WP2 correction gate (leftover-0)

TICK=yes for the VF2-WP2 **correction gate** only.
Plan checkbox **not** ticked. `CORRECTION_GATE_VF2_WP2` **not** cleared.
Parent 20-8 unchanged (R9-WP4 `[ ]`, 59/60, G6 `[ ]`).
Dirty main working tree **not** official-run.

## Reproduction (this critic)

- Isolated `--path`: `D:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\_vf2wp2_gate_product`
- Recomputed `source_tree_sha256` = `2e9c3bb3778812acb2c078cb7faac1d0e5fed0c403b01704b48574b67e531831` MATCH
- `python tests/check_locomotion.py` (isolated) EXIT 0
- Godot 4.7.1-stable console `--headless --path <isolated> --script res://tests/run_locomotion.gd` EXIT 0
- leftover Godot on isolated `--path` = 0 (before and after)
- Independent banners: HASH2=match HASH2_SOURCE=outcome_hash2; TUNNEL=none TUNNEL_SOURCE=outcome_tunnel; CAMERA=arena_fit CAMERA_SOURCE=outcome_camera; USED_APPLY_FRAMES=1205 attempted=1205 succeeded=1205
- Governance: `test_authoritative_plan.py` EXIT 0; `test_vault_fighters_plan.py` EXIT 0 next=VF2-WP2 ticked=8 parent frozen

## Hunts

1. Source hash — MATCH (isolated). Main dirty tree MISMATCH (quarantined; not used).
2. Isolated check + headless leftover-0 — PASS.
3. run_id reuse `-01`/`-02-continue` — MISS (official harness is unique `-03`; old dirs remain logs-only history).
4. Evidence logs-only — MISS (`-03` has run.json / hashes / seed / command_id / timestamps / verdict / screens / outcomes).
5. HASH2/TUNNEL/CAMERA fail-string inferred — MISS (structured `outcome_*` dictionaries; banners cite those sources).
6. USED_APPLY_FRAMES +1 per attempt/path — MISS (attempted/succeeded split; succeeded only after `apply_frames` ok; 1205/1205 reproduced).
7. Camera only `camera_framing()` — MISS (Viewport.get_visible_rect + get_camera_2d + Camera2D.zoom/position; `not_product_helper=true`).
8. Checker loosened / plan ticked / parent mutated — MISS (isolated checker is stricter than HEAD; VF2-WP2 still `[ ]`; CORRECTION_GATE still REQUIRED; 8/50; parent frozen).

## Attacks that landed

None that fail the correction gate.

## Residual nits (do not block TICK)

- This leftover-0 critic reproduced **headless** only (hunt 2). Implementer window log + 1280x720 screens exist; not re-run here.
- Claimed pack `started_at==ended_at` same second; this repro has 13:26:48→13:26:49.
- `metrics.json` RSS is a hint string, not measured process RSS.
- `source_tree_sha256` is the 16-file locomotion manifest, not a whole-tree hash.

## Honesty

- 60 Hz is `ledger:RL-SIM-FIXED-60` assumption, not observed Y8 clock.
- Hold-to-aim assumption. Roll/dive unavailable.
- Camera `arena_fit` assumption; independent viewport covers rooftops.
- Not Y8 parity. Not V0.
- Isolated official path only. Dirty main sprint/roll tree quarantined.
