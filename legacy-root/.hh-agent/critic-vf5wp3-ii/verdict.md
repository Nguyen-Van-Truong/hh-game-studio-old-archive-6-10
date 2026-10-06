# Hostile Critic II — VF5-WP3 leftover-0

**TICK=yes** for VF5-WP3 only. Product not edited. Plan not ticked. Parent not mutated. No commit.

## Independent leftover-0

- HEAD `535e29dade4f215d8beadc5181a21ebbd868dee8`
- Recomputed source tree `e24d46bf2d2d90ea4739377d6777ecab9f822344531e3b2991be10cc90878649` MATCH (31/31 files)
- Isolated `--path` `.hh-agent/critic-vf5wp3-ii/iso` (product busy with HH windowed run)
- Windowed `run_warehouse.gd` pin 4.7.1-stable, seed 13, `fail_count=0`, DISPLAY=Windows
- APPLY **2647/2647** match claimed / official outcomes
- leftover Godot on iso `--path` = 0; leftover on product `--path` = 0
- Six window stills pairwise-distinct and byte-identical to official evidence hashes
- File checks: `check_warehouse` / `check_map` / `check_rooftop` / `check_dive` all EXIT 0

## Hunts

1. Source + isolated window leftover-0 + APPLY: **pass**
2. Cover: live `apply_frames` melee → `apply_melee` → `apply_damage` (fists 10, wood HP 10). Not `take_damage(999)`. `blocked_before` is `has_cover_at` AABB, not a recorded shot-through miss. Residual.
3. Cargo: live climb + melee → `release_hang` / `drop_events`. Not a scripted flag write. **pass**
4. Zones: live bodies, no teleport. office_loft standing on_floor; east_floor standing; west_catwalk standing still after `up` on ladder. mid/east first-hits are on_ladder through fat AABB. Graph helper honestly false for office/east_floor. **pass**
5. Camera 1024×192 measured from `storage.json` (64×12×16) and fits 1280×720; stills show letterboxed full strip. Weapons (5,4)(30,10)(36,5)(48,1) not in blockers; walk support 1 tile below; no pit layer. **pass**
6. Vertical ambush: isolated catwalk still P1 on_floor west_catwalk y≈20 after climb_up 146/208. Lift placed, never ridden. **pass**
7. Plan VF5-WP3 still `[ ]`. Parent R9-WP4 `[ ]`, 59/60, G6 `[ ]`. `rooftops.json` blob matches HEAD. No Y8 display/rip. Official `run_all` `NO_ERRORS=proven`. **pass**

## TICK=no gates

- V-A18: timestamps, run/trace/source hash, repro command present
- Not fixture/teleport/graph-only for cover-break / cargo / zones
- Stills are pause overlays, `lose_visible=false`, actors alive
- Display **Pallet Annex**, title **Vault Fighters**, not Storage / Superfighters

## Residual nits (not TICK=no)

- Cover "blocked" is occupancy AABB, not a live intercepted shot at a fighter
- Cover `source` string says P2/mid_floor; code is P1/west_floor
- mid_catwalk / east_catwalk first `ware_zone_hit` are on_ladder, not standing
- `annex_lift` placed, never ridden
- Banner APPLY 2101 is pre-still staging; outcomes 2647 include staging
- `office_loft` is floor-height side room (y=8), not a raised loft
