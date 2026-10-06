# VF5-WP2 verdict

PASS Skyline Relay rooftop/bridge arena (V-A18 / §18.3).
Not Y8 parity. Not V0. Plan checkbox **not** ticked. No implementer commit.

## DoD / Verify (quoted from 29-8 VF5-WP2)

Verify: P1/P2/bot reach all combat zones; pit and fallback tests; screenshot
landmarks; no copied billboard/geometry.

DoD: vertical scramble và high-ground tactics hoạt động.

## Run

- `run_id`: `VF5WP2-20260830-ASIA-SAIGON-01`
- `command_id`: `cmd.vf5-wp2.skyline-relay.1`
- seed `12`, mode `vs2`, map `rooftops` display **Skyline Relay**
- NAME=pass ELEV=pass ZONE=pass COVER=pass P1=pass P2=pass BOT=pass PIT=pass FALLBACK=pass LIVE=pass REPLAY=match
- LIVE hud=Skyline Relay real=True
- P1 hits={'mid_deck': True, 'west_bridge': True, 'west_deck': True}
- COVER blocked_before=True breaks=1 real=True
- events kinds include name/zone/p1/pit=True kinds=['roof_bot', 'roof_cover', 'roof_live', 'roof_name', 'roof_p1', 'roof_p2', 'roof_pit', 'roof_replay', 'roof_zone']
- window stills pairwise_distinct=True
- still hashes: {'rooftop_setup_1280x720.png': {'sha256': '2369995909461594a599a7fc5c378cbab21b9af4c2be52bbcb22197b19003d18', 'bytes': 36585}, 'rooftop_title_1280x720.png': {'sha256': '4cfb29a75753609970bf3365bfe06443e4e32a838ff382be4ee99ac7708022f1', 'bytes': 48353}, 'rooftop_bridge_1280x720.png': {'sha256': '0e69c2891a3f78d3a4cc9da979762a173ca1ea055b34cd12553b6c6363bf3742', 'bytes': 37556}, 'rooftop_cover_1280x720.png': {'sha256': 'c8be9f0f7b36778847f1f13905b16876b383c7aed4563bfede494a1c33664d54', 'bytes': 56211}, 'rooftop_pit_1280x720.png': {'sha256': '09309e515db7923be1351ab74b502c1dbe98f621d799ba5195ab616ae83884f7', 'bytes': 50365}}
- still errors: []
- `USED_APPLY_FRAMES=1157` attempted=1157
- source_tree_sha256 `d6841c3c1222f7f47e0d3e08c0b7b877f0bc49079f8c6ab434647acd4a22d6ff`
- base_head `65399c8f0dce4d51ef28685a1529bdfd9114506b`
- Banners copy `RooftopCases.outcome_*`. They are not inferred from fail-substrings.

## Reproduction

```
python godot/dogfood/superfighters/tests/check_rooftop.py
python godot/dogfood/superfighters/tests/check_map.py
$godot_console --headless --path godot/dogfood/superfighters --script res://tests/run_rooftop.gd
$godot --path godot/dogfood/superfighters --script res://tests/run_rooftop.gd
$godot_console --headless --path godot/dogfood/superfighters --script res://tests/run_all.gd
```

EXIT 0 / 0 / 0 / 0. leftover Godot on product `--path` = 0.

## Honesty

- 60 Hz is `ledger:RL-SIM-FIXED-60` assumption, not observed Y8 clock.
- Skyline Relay topology stays assumption (`ledger:RL-MAP-SKYLINE`).
- Jump envelope is product tuning (dx=10 / dy=4); live apex is ~3.4 tiles.
  Additive ladders make high ground reachable without rewriting that envelope
  into observed Y8.
- `ledger:RL-NADE-PROP` stays `deferred`.
- Hold-to-aim stays `ledger:RL-CTRL-HOLD-AIM` assumption, not observed.
- Y8 roll/dive observation stays `ledger:RL-MOVE-ROLL-DIVE` unavailable.
- Live `c`/`b` still paint as tiles on other maps. This WP placed original
  breakable cover on Skyline Relay only.
- Machines / water / toxic / lifts / doors stay fixture-only. Ladders satisfy
  the ladder/elevator-or-moving-route beat.
- Display names Storage / Police Station / Hazardous stay
  `ledger:RL-DELTA-MAP-NAMES` debt until VF5-WP3+.
- No new in-game Y8 play this WP. Not a copied billboard or Y8 collision map.
- Not Y8 parity. Not V0.
- Parent 20-8 unchanged: R9-WP4 `[ ]`, 59/60, G6 `[ ]`.
