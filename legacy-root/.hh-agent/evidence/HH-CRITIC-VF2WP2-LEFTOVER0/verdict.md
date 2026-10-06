# Hostile Critic HH leftover-0 — VF2-WP2 only

Timezone: Asia/Saigon. Model: cursor-grok-4.6-xhigh-fast.
Product not edited. Plan not ticked. VF2-WP3 not started.
Parent freeze still: R9-WP4 [ ], 59/60, G6 [ ].

## TICK=yes

Official leftover-0 reproduced. Residual nits only.

## Official leftover-0 (reproduced)

| Check | Result |
|---|---|
| `python tests/check_locomotion.py` | PASS |
| Godot pin 4.7.1-stable `--headless --script res://tests/run_locomotion.gd` | PASS |
| Same script, Windows window (`DISPLAY=Windows`) | PASS |
| Banners | `HASH2=match TUNNEL=none CAMERA=arena_fit USED_APPLY_FRAMES=366` both runs |
| Honesty banners | `HOLD_AIM=assumption ROLL=unavailable CLOCK=RL-SIM-FIXED-60` |
| Uncommitted loco tree | yes (matches claim) |
| Plan VF2-WP2 | still `[ ]` |
| Agent evidence `docs/evidence/VF2WP2-20260829-ASIA-SAIGON-01/` and `-02-continue/` | dirs exist, **0 files** |

Godot leftovers: none at start/end. One `--path` at a time.

## Hunts (ran)

1. **One-way from below / drop-through** — from-below on hazardous **passes** (min_y=25.8, not blocked). Crouch **does not** drop through (stays on platform). Drop-through is unshipped (VF2-WP5 owns it). Official `no_tunnel_oneway` is 48 idle ticks + jump-land; it never probes from-below or drop.
2. **Police pit-lip in official traces** — `pit_fall` dies tick 35 at x=32.2 (left of floor x=96), cause=pit, `lip_fall_frames=0`. `walk_accel_friction` y stays 176–180, `sunk_frames=0`. Old pit-lip fall-through **not** in these official traces.
3. **HASH2 ignores y / collision** — **miss**. Snapshot + epsilon compare **x and y**. `on_floor` is not hashed (weaker, not enough to hide a floor clip that moves y).
4. **USED_APPLY_FRAMES hardcoded** — **miss**. Live counter; 366 reproduced. Unlike VF2-WP1 `USED_STEP_FIXED=0` string. Residual: `run_all.gd` still derives HASH2/TUNNEL/CAMERA from `_loco==proven`.
5. **Camera follow P1** — does **not** follow (cam stays 512,128 while P1 +105x). By design: `arena_fit`, `follow_living=false`. Not a DoD fail.
6. **Jump height vs epsilon 0.001** — hold rise 53.797 vs ballistic 54.382, delta 0.585. Official case only checks hold > tap+4px. Across-run snapshot epsilon still holds.
7. **Plan ticked** — **no**. VF2-WP2 `[ ]`.
8. **ObjectDB on `run_all.gd`** — I ran it leftover-0. PASS, no ObjectDB/AudioStream warning in log.

## Honesty

- 60 Hz is `ledger:RL-SIM-FIXED-60` **assumption**, not observed Y8.
- Hold-to-aim **assumption**. Roll/dive **unavailable**.
- Camera `arena_fit` **assumption**; not a Y8 camera claim; does not follow P1.
- Not Y8 parity.
- Agent evidence pack is an empty folder; critic leftover logs are the proof.

## Residual (OK, do not block)

- Empty agent evidence dirs (ledger still cites them).
- Drop-through unshipped (VF2-WP5).
- Jump height not proven to 0.001 vs ballistic.
- `run_all.gd` loco banner is derived.
- Uncommitted (expected until coordinator commit).
