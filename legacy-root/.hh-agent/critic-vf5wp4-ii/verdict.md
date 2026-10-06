# Hostile Critic II — VF5-WP4 leftover-0

**TICK=yes** for VF5-WP4 only. Product not edited. Plan not ticked. Parent not mutated. No commit. VF5-WP5 not started.

## Independent leftover-0

- HEAD `d9a09af4256049c1b4cdbae613c8f41323fde378` plus uncommitted WP4 work
- Recomputed source tree `d6e32228d14d5dcfc1fe95e39ba9c481d640c38290bb4f2287b207db8bb4d6b6` MATCH (37/37 files)
- Isolated `--path` `.hh-agent/critic-vf5wp4-ii/iso` (did not write product `.evidence`)
- Windowed `run_station.gd` pin 4.7.1-stable, seed 14, map `police` / Signal Court, mode `vs2`
- `fail_count=0`, DISPLAY=Windows, EXIT 0
- Banner APPLY **2828/2828**; outcomes APPLY **4205/4205** — both match the claim
- leftover Godot on this iso `--path` = 0; leftover on product `--path` = 0
- Seven window stills pairwise-distinct and byte-identical to official evidence hashes
- File checks: `check_station` / `check_warehouse` / `check_rooftop` EXIT 0
- `test_authoritative_plan.py` EXIT 0; `test_vault_fighters_plan.py` EXIT 0 next=VF5-WP4

## Hunts

1. Source + isolated window leftover-0 + APPLY: **pass**
2. GRAPH vs live: P1 live 9/9 zones via `apply_frames`. east_top / west_loft standing proven by later stills (`on_floor`, `lose_visible=false`, Pause) and `floor_standing`. sky_bridge first-hit is standing `on_floor` at x=574.78 (fat-pad residual). Not graph-only. **pass**
3. Machine: `give_weapon` inventory only; fire is `apply_frames` → `_step_bullets` → `_sweep_bullet` env → `apply_rotor_shot` → `take_shot`. Isolated `shots=2` `jams=1` `ledger_jam=1` `spin_before=true`. Not `jammed=true` poke. **pass**
4. Floor stills: court / floor1 west_hall / floor2 west_loft / floor3 east_top / machine all alive, `on_floor`, not hanging, not lose. `jump_vel=-430` ≈ 7.2 px/frame. No teleport/`global_position=` in `station_cases.gd`. **pass**
5. Spawn AABB (tile-center) off pit columns x=0–6 y≥12 and off rotor (120,184) 24×24. Idle `p1_dead=false` `p2_dead=false`. **pass**
6. Two live routes: P2 door-plate walk → west_hall → west_loft (`climb_up=31`); BOT east_hall → east_mid → east_top (`climb_up=46`). Layout is courtyard + west interior + sky bridge + east tower, not a flat rectangle. Trace `stat_zone_hit` + still per named floor. **pass**
7. Plan VF5-WP4 still `[ ]`. Parent R9-WP4 `[ ]`, 59/60, G6 `[ ]`. `rooftops.json` / `storage.json` sha256 match HEAD. No Y8 display/rip. Title **Vault Fighters**. HUD **Signal Court**. Isolated window log has no ObjectDB/ERROR/WARNING. Official `run_all` already `HH_VF_ROOF`/`HH_VF_WARE`/`HH_VF_STAT` proven. **pass**

## TICK=no gates

- V-A18: timestamps, run/trace/source hash, repro command present
- Not fixture/teleport/graph-only for door / machine / floors / zones
- Stills are Pause overlays, `lose_visible=false`, actors alive
- Display **Signal Court**, title **Vault Fighters**, not Police Station / Superfighters
- Spawn not in a pit; layout not a flat rectangle
- Machine jam is live fire, not a poke

## Residual nits (not TICK=no)

- Banner APPLY 2828 is pre-still staging; outcomes 4205 include staging
- east_top / west_loft first `stat_zone_hit` are air/climb through fat AABB; standing is later settle/still
- sky_bridge first standing hit is 1.22 px west of tile 36 (fat pad); later crossing is unlogged
- `signal_lift` placed, never ridden (honesty-only)
- Parallel HH critic Godot was on `.hh-agent/critic-vf5wp4-hh/iso` during this leftover-0; not product, not this iso
- Isolated leftover-0 did not re-run full `run_all.gd`
