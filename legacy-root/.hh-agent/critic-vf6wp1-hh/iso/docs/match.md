# Match rules — VF6-WP1

Display title: **Vault Fighters**. One canonical match state machine
(`src/sim/match.gd`, `data/sim/match.json`) is used by vs1, vs2, Stage,
and the reserved Survival slot.

Clock is `ledger:RL-SIM-FIXED-60` (`assumption`). Hold-to-aim stays
`ledger:RL-CTRL-HOLD-AIM` (`assumption`). Y8 roll/dive observation stays
`ledger:RL-MOVE-ROLL-DIVE` (`unavailable`). Not Y8 parity.

## Phases

`boot → menu → countdown → active ⇄ paused → resolved | quit`

`test_driven` skips countdown ticks (`RL-MATCH-COUNTDOWN`, assumption,
not observed). Live play uses a short product countdown.

## Outcomes and end reasons

| Outcome | End reason | Official proof |
|---|---|---|
| win | `last_standing` | `tests/traces/match/match_win.json` apply_frames |
| lose | `p1_down` | `tests/traces/match/match_lose.json` pit walk |
| tie | `timeout` | `match_tie.json` — **approximation**, timer not observed |
| quit | `quit` | walk frames then `match_ops` quit + title |

After quit the title shows `Last match ended: quit` so a player can tell
the round ended and start again from the mode buttons.
| restart | `restart` / fresh `play` | `match_restart.json` `restart_same` |

`all_down` (same-tick wipe) is implemented in `MatchRules.evaluate` and
is not the official tie trace. Official tie is the labeled timeout.

## Teams and friendly-fire

- vs1 / Stage / Survival: FFA, `friendly_fire=false` (`RL-HIT-FF`, assumption)
- vs2: two teams, `friendly_fire=true`

Spawn seed stays `7 + stage * 13` (`RL-MATCH-SEED`). Mode/map are not
mixed so VF1–VF5 official seeds stay 7.

## Pause

Pause freezes `SimClock`, rejects `apply_frames`, and does not step
physics/combat. Resume discards leftover wall time. Official pause
proof is a dual-clock: authored trace ticks may continue while
`sim_tick` and body hash stay frozen; resume retimes frames back to
the frozen sim tick. `snapshot_hash()` is physics/combat identity and
must stay stable across pause. Lifecycle (phase/outcome/round_id) is
exported on every transition as `post_phase` plus a separate
`match_hash`.

## Official path

No `teleport`. No `force_kill`. Fixture `force_kill` remains for
`tests/traces/fixture/` only.

P2/bot stay **smoke** until VF6-WP5. Art stays VF7.
