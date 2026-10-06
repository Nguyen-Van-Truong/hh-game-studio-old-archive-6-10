# Hostile Critic HH — VF5-WP3 leftover-0

TICK=yes

Product not edited. Plan not ticked. No commit. Parent 20-8 untouched.
Independent leftover-0 iso: `.hh-agent/critic-vf5wp3-hh/iso`

Windowed `run_warehouse.gd` DISPLAY=Windows, fail_count=0, apply
2647/2647. Headless `run_all.gd` EXIT 0. Product `--path` leftover=0
before/after both.

## Hunts

1. Source hash `e24d46bf2d2d90ea4739377d6777ecab9f822344531e3b2991be10cc90878649`
   recomputed match. hashes.txt 0 mismatches. Isolated window
   outcomes/events/snapshots **and** six stills byte-identical to pack.
   Pairwise-distinct. Catwalk/cover/cargo/office stills alive/standing/
   zone/no-lose. Pause overlay, not lose.
2. Door is **not** teleport. Remote plate at x=256 opens `annex_door` at
   x=560 (collider disable), then `_walk_toward(608)`. First
   `office_loft` hit is x=572.21 y=163.99 on_floor (4px slack of raw
   576). Unused `_vault_into_office` leftover. No closed-door negative.
3. Lift is **unused**. `warehouse_cases` only checks placement count.
   No board/ride/snap-Y of `annex_lift`. First catwalk/east_catwalk
   hits are AABB slack / on_ladder; west_catwalk still is standing
   on_floor at x=401.83 y=19.99. Not y−1 graph helper for official
   stills.
4. Isolated `run_all` leftover-0 EXIT 0. DIVE MAPS=pass 1229/1229.
   ENV 1723/1724 MOVING 1800/1801 HAZARD 723/723 BREAK 880/880.
   ROOF 1229/1229 WARE 2101/2101. annex_door/lift/cover did **not**
   add tests to ENV/MOVING/HAZARD/BREAK. Counts unchanged vs VF5-WP2.
5. Weapon homes 4/4 have walk support 1 tile below. No pit (y=11
   solid 64/64). `[48,1]` and `[36,5]` are mid-air above one_way
   catwalks, not pit-adjacent.
6. VF5-WP3 `[ ]`. HUD/title **Pallet Annex** / **Vault Fighters**.
   No Superfighters display. No ObjectDB. Ledger `RL-MAP-PALLET`
   assumption, not observed. `rooftops.json` unchanged vs HEAD
   `535e29d`. Only `docs/rooftop.md` name note + `app.gd` stage
   string. `-01` hash not drifted. R9-WP4 `[ ]` 59/60 G6 `[ ]`.

## DoD

Quoted Verify: cover blocks then breaks (melee, blocked_before,
breaks=1); cargo hangs then drops; P1 live body 7/7 including
standing office; camera covers 1024x192; weapon homes supported.
DoD close-quarters cover and vertical catwalk/cargo are functional.
Not copied billboard. Not Y8 parity. Not V0.

Residual nits OK: lift placement-only; office_loft is same-floor
gated strip (not elevated loft); cover source string says P2/mid
but code is P1/west; first zone hits slack/on_ladder; P2/bot 2/7;
MapGraph east_floor/office_loft=false (honest); banner APPLY 2101
vs outcomes 2647 (still staging); two mid-air hanging pickups.
