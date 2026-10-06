# Hostile Critic II — VF6-WP1 remint `-04`

TICK=yes

Independent leftover-0 iso: `.hh-agent/critic-vf6wp1-ii-04/iso`
Console twin. Product not edited. Plan checkbox not ticked. VF6-WP2 not started.

## Independent leftover-0

- Recomputed freeze `2636b77489438a74e570b18cfbd61bce866506096bb8c3b17d686a1c9d00b461` MATCH (118/118, no drift).
- Isolated windowed `Godot_v4.7.1-stable_win64_console.exe --path iso --script res://tests/run_match.gd`
- Host `WaitForExit` **0** in **85.1s** (not -1). Hung=false. Leftover on this iso **0**.
- Banner `FINISHED=1 PROCESS_EXIT=0`. No ObjectDB/AudioStream/WARNING/ERROR.
- MACHINE_MODES=`vs2,vs1` SURVIVAL_SHIPPED=0. `app.gd` never starts survival. Title has no Survival button.
- Official stills bitwise-match this leftover-0 except `match_restart` (render/walk pose drift only).

## Hunts

1. Freeze before official Godot, hash live==claim: **pass**
2. Isolated leftover-0 windowed console `run_match.gd` <4 min exit 0 leftover 0: **pass**
3. MACHINE list vs `app.gd`: Survival not shipped / not on MACHINE: **pass**
4. Official beats title/`push_input`/`parse_input_event`, not apply_frames-only: **pass**
5. Plan `[ ]`. No ObjectDB. Restart rematch 2-tap stays WP2: **pass**

## Residual nits (not TICK=no)

- `apply_frames` still steps the sim after typed events (380/382). Allowed; not the sole row.
- Tie is a labeled timeout approximation (`TIE_OBSERVED=0`).
- P2/BOT smoke. Not AI. Not Y8 parity.
- Stage constructs MatchRules from title; no official stage lifecycle this WP.
- Survival reserved for VF6-WP4.
- Restart still not bitwise stable across leftover-0 remints.
- Critic II did not independently remint official `run_all.gd` (packed host exit 0 / 1467.9s).
- Art still VF7. Parent 20-8 remains 59/60.

HEAD `2b1e0a2`. Title **Vault Fighters**. 29/50.
