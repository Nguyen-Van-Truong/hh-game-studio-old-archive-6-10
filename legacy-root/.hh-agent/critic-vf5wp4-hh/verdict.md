# Hostile Critic HH — VF5-WP4 leftover-0

TICK=yes

Product not edited. Plan not ticked. No commit. Parent 20-8 untouched.
Independent leftover-0 iso: `.hh-agent/critic-vf5wp4-hh/iso`

Windowed `run_station.gd` DISPLAY=Windows, fail_count=0, apply
4205/4205 (banner 2828). Headless `run_station.gd` EXIT 0, outcomes
byte-match pack still rows. Headless `run_all.gd` EXIT 0. Product
`--path` leftover=0 before/after official critic runs.

## Hunts

1. Source hash `d6e32228d14d5dcfc1fe95e39ba9c481d640c38290bb4f2287b207db8bb4d6b6`
   recomputed match. hashes.txt source 0 mismatches. Isolated headless
   outcomes/events/still-rows match pack (APPLY 4205/4205; MACHINE
   jammed shots=2; floor stills standing west_hall / west_loft /
   east_top). Windowed leftover-0 retry PASS. First five stills
   byte-identical to pack. Pairwise-distinct. Pause overlay, not lose.
   HUD **Signal Court**.
2. Rotor jam is **not** a script flag. `give_weapon("uzi")` is inventory
   only; fire is `apply_frames` hold `fire`. Jam path is
   `_step_bullets` env sweep → `apply_rotor_shot` → `take_shot`.
   Independent run: spin_before, jammed, jams=1, ledger_jam=1, shots=2.
   Packed `events.jsonl` is StationCases `stat_*` only — no
   `fire_spawn`/`bullet` line. Residual V-A18 completeness, not
   “never shot.”
3. Door is **not** teleport. Plate at x=300 opens `signal_door` at
   x=408 (collider disable), then `_walk_toward(472)` into west_hall.
   `signal_lift` unused. Loft proof is west ladder `_board_loft`, not
   lift snap.
4. Leftover `map_police.json` is a VF2 short walk (24 ticks right),
   not official per-floor InputTrace. Official floor proof is
   `apply_frames` settle + screenshots. Pack floor1/2/3 stills are
   standing Pause, not title cards. Critic windowed #1 hung after
   floor2 (killed). Windowed #2 leftover-0 completed; floor3/machine
   PNGs were 2KB failed captures vs pack ~55KB. Pack floor3/machine
   stills remain the official landmark stills; structured still rows
   match leftover-0 headless/window2.
5. Isolated `run_all` leftover-0 EXIT 0. DIVE MAPS=pass 1253/1253.
   ENV 1723/1724 MOVING 1800/1801 HAZARD 723/723 BREAK 880/880.
   ROOF 1229/1229 WARE 2101/2101. MAP SCHEMA 36/36. `L` lossless
   encode of ladder+one_way overlap did **not** break dive/warehouse.
   rooftops.json / storage.json hashes unchanged vs HEAD `d9a09af`.
6. VF5-WP4 `[ ]`. HUD/title **Signal Court** / **Vault Fighters**.
   No Superfighters display. No ObjectDB. Ledger `RL-MAP-SIGNAL`
   assumption, not observed. `-01` hash not drifted. R9-WP4 `[ ]`
   59/60 G6 `[ ]`.

## DoD

Quoted Verify: traversal graph helper + live apply_frames reach;
machine event (live bullet jam); safe floor collision on three
named floors; no pit spawn; screenshot + apply_frames still-row
per floor.
DoD multi-route station fight: courtyard + west hall/loft + sky
bridge + east hall/mid/top, not a flat rectangular grid. P1 live
body 9/9. Not copied billboard. Not Y8 parity. Not V0.

Residual nits OK: unused `signal_lift`; packed events omit
`fire_spawn`; leftover `map_police.json` short walk; banner APPLY
2828 vs outcomes 4205 from still staging; first zone hits often
AABB slack / on_ladder; P2 4/9 bot 3/9; critic windowed #1 hang
after floor2; windowed #2 floor3/machine PNG flake (2KB);
`police_interior_floor_solid` checks only x=22..45 of row 12.
