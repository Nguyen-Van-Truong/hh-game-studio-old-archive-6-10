# Bots — Vault Fighters

Sidecar for VF6-WP5. Display title remains **Vault Fighters**.
Planner rows are `ledger:RL-BOT-*` (`assumption`). Not observed Y8.
Not a Superfighters trademark use.

Official `run_id` is `VF6WP5-20260903-ASIA-SAIGON-02`
(`cmd.vf6-wp5.bots.2`). Pack `-01` is void (finish miss after a
nade-delay experiment).

## What shipped

Bots use a seeded planner instead of the old greedy weapon-then-chase
loop:

- platform / ladder graph from `MapGraph` + bounded A*
- threat / cover / pickup / attack / retreat intents
- weapon mix: mid-range nade then erred gun; fists only when close
- aim error and reaction delay (no perfect aim)
- pit / hazard / incoming-bullet avoid (stay on the platform)
- knockdown recovery wait
- recruit / regular / veteran profiles in `data/sim/bots.json`

Difficulty knobs are reaction delay, aim error degrees, tactical
budget, and recovery ticks. They are HUD-visible on the VS stage line
(`Bot skill regular · delay … · aim±…°`). Values are product tuning.

## Honesty

- No teleport. Official proof is `think()` → `apply_frames` on the six
  catalog VS maps.
- No hidden HP/ammo through walls. Perception is line-of-sight or a
  short hearing radius; last-seen foe stale after 45 ticks.
- Map topology is public (a player who knows the arena).
- Hold-to-aim stays discrete (`ledger:RL-CTRL-HOLD-AIM` assumption).
  Aim error is applied to that discrete cone, not an analog stick.
- Survival / Stage official banners stay `NOT_AI=1` because those
  packages did not remint planner postconditions. Live Survival/Stage
  bots still use this brain.
- Not Y8 parity.

## Residual

Overlay 31-8 3 seed × 2 skill × 2 opponent matrix is AUTHORITY=0 and
not claimed. Analog aim and art are VF7.
