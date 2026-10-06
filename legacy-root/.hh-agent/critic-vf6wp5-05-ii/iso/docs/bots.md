# Bots — Vault Fighters

Sidecar for VF6-WP5. Display title remains **Vault Fighters**.
Planner rows are `ledger:RL-BOT-*` (`assumption`). Not observed Y8.
Not a Superfighters trademark use.

Official `run_id` is `VF6WP5-20260904-ASIA-SAIGON-05`
(`cmd.vf6-wp5.bots.5`). Packs `-01`, `-02`, `-03`, the 20260903 `-04`
id, and `VF6WP5-20260904-ASIA-SAIGON-04` are void.

## What shipped

Bots use a seeded planner instead of the old greedy weapon-then-chase
loop:

- platform / ladder graph from `MapGraph` + bounded A*
- threat / cover / pickup / attack / retreat / patrol intents
- two live weapon classes proven from ledger (`fire_spawn` plus
  `explosion` or melee `hit`), not starter-kit hold counters
- aim error rotates the actual shot direction (`aim_x`/`aim_y`);
  official proof is a measured miss versus the geometric center.
  Bots do not have perfect aim.
- pit avoid is a route-around (backtrack / other platform / jump),
  not a freeze at the lip. Same-Y pit lips are not A* walk edges.
- airborne spawn/fall paths from the landing floor, not an air cell
  treated as a high deck. A held hop keeps air-x so a closed door
  can be cleared; falling before a hop does not air-walk into crates.
- knockdown recovery wait
- recruit / regular / veteran profiles in `data/sim/bots.json`

Difficulty knobs are reaction delay, aim error degrees, tactical
budget, and recovery ticks. They are HUD-visible on the VS stage line
(`Bot skill regular · delay … · aim±…°`). Values are product tuning.

Greedy baseline walks straight at the foe with no pit graph. Planner
compare may use a greedy pit-death delta as supporting evidence, but
the planner must also arrive on that rooftops seed. Fire deaths are
not pit deaths.

Finish proof despawns unused vs1 extras and keeps exactly two
fighters (bot vs bot). The champion must have moved and fought;
the loser must die by damage. An idle full-HP teammate is not
last-standing.

Reach proof is the named opponent start (`goal_dist < 36`), the
first A* cell at least 72px from start (`waypoint_dist < 48`),
melee/engage range (`engage_dist < 72`), or the named foe down
after a proven close (`closest_engage < 72`). A long-range shot,
a 27px shuffle, walking away, or a reroute counter is not reach.

## Honesty

- No teleport. Official proof is `think()` → `apply_frames` on the six
  catalog VS maps.
- No hidden HP/ammo through walls. Perception is line-of-sight only
  (no 320px sight cap; walls still block). `hearing_px` only ranks
  already-visible foes. After LOS breaks, bots may walk to the frozen
  last-seen point for 16 ticks, then patrol public spawn pads. They
  do not track a live body through walls. A null physics space is not
  a foe.
- Map topology is public (a player who knows the arena).
- Hold-to-aim stays the human discrete cone
  (`ledger:RL-CTRL-HOLD-AIM` assumption). Bot aim error is an analog
  override on that command so the bullet leaves on the erred vector.
- Official `run_all` does not default `HH_VF_BOTS_COMPACT`.
- Survival / Stage official banners stay `NOT_AI=1` because those
  packages did not remint planner postconditions. Live Survival/Stage
  bots still use this brain.
- Not Y8 parity.

## Residual

Overlay 31-8 3 seed × 2 skill × 2 opponent matrix is AUTHORITY=0 and
not claimed. Art is VF7.
