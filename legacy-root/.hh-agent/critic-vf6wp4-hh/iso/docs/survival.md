# Survival — VF6-WP4

Display title: **Vault Fighters**. Survival is an endless wave/score
run, **not** a Stage campaign checkpoint. Title **Survival** starts a
new director. Dying ends the run and shows the score. Rematch or
pause Restart clears the director and starts a new run.

Wave count, spawn rate, kill/combo/time points, and entity caps are
`ledger:RL-SURVIVAL-LOOP` / `RL-SURVIVAL-WAVE` /
`RL-SURVIVAL-SCORE` / `RL-SURVIVAL-SPAWN` (**approximation**, not
observed Y8). Records are `ledger:RL-SURVIVAL-RECORD` (assumption).
Bots stay smoke. Art stays VF7.

## Player path

| Step | What happens |
|---|---|
| Title **Survival** | New run on the current VS map (default Skyline Relay). Score 0, wave 1. Stage save is untouched. |
| Play | Director spawns bots on a cooldown, under a living-bot cap. Weapon/prop drops refresh on a timer. Score rises on time survived, kills, combo, and wave clear. Last standing does **not** end the run. |
| Pause | Sim tick, director, and score freeze. Resume continues the same run. |
| Death | Game over. Overlay shows score / wave / combo. This is not a Stage loss checkpoint. |
| Rematch / Restart | New run. Director score/wave/combo reset. Best-score record may update. Stage `current_index` does not change. |
| Title | Stage button still reads Stage / Continue Stage from the campaign save. Survival stays **Survival**. |

## How this is not Stage

- Stage advances a four-map catalog and keeps `user://vf_stage/progress.json`.
- Survival never calls `StageRules.record_win` and never loads a Stage continue map.
- Survival rematch is a new run, not "stay on this arena / keep the checkpoint".
- Best score lives at `user://vf_survival/records.json` (write `.tmp`, park `.bak`, rename). Official/test runs may set `HH_VF_SURVIVAL_STORE`.

## Caps and seed

Living bots cap at 6. Pickups cap at 12. Seed stays `7 + stage * 13`
(`ledger:RL-MATCH-SEED`); Survival uses stage index 0 so official seed
is 7. Mode/map are not mixed.

## Official path

No teleport. No `force_kill`. No `apply_eval` rematch. Title Survival
uses viewport clicks. Score monotonic and spawn-cap samples come from
live `apply_frames`. Pause freezes the director. Death is a live
fight outcome. Restart proves a cleared director. Official soaks are
10-minute headless and 5-minute window wall-clock. P2/bot stay smoke
(`NOT_AI=1`). Loop/wave/score/spawn stay approximation. Not Y8 parity.
