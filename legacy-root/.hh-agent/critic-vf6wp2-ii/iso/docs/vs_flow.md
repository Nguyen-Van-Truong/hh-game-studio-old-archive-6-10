# VS production flow — VF6-WP2

Display title: **Vault Fighters**. VS 1P and local VS 2P now share one
player path: **title → mode → ready/start → fight → result → rematch**.
The canonical match machine from VF6-WP1 is unchanged. Survival is
**not shipped**. Stage still has a title button; its progression loop
stays VF6-WP3.

First-run and rematch numbers are a product UX contract
(`ledger:RL-VS-FIRST-RUN`, `ledger:RL-VS-REMATCH`, `assumption`), not
an observed Y8 listing. Hold-to-aim stays `ledger:RL-CTRL-HOLD-AIM`
(`assumption`). 60 Hz stays `ledger:RL-SIM-FIXED-60` (`assumption`).
Not Y8 parity.

## Player path

| Step | Control | Actions |
|---|---|---|
| Title | VS 1P or VS 2P (default map already selected) | 1 |
| Ready room | Start (P1 auto-ready; vs1 bots ready; vs2 P2 auto-ready on local keyboard) | 1 |
| Fight | P1 arrows + N/M/, · P2 WASD + 1/2/3 | — |
| Result | Rematch (same mode/map) or Title | 1 |

First-run target: **≤3 actions, ≤30s**. Official path is two taps
(mode + Start). Rematch target: **≤2 actions, ≤5s**. Official path is
one Rematch tap. Input must move a body within **2 sim frames**.

## Isolation

P1 and P2 keep separate InputMap prefixes and keys. Official leak
proof injects P1 `KEY_RIGHT` / `KEY_N` and P2 `KEY_A` / `KEY_1` while
reading **both** live slots. P1 input must not move or swing P2.
Team colors stay Blue (P1) and Red (P2).

Bots remain **smoke** (`BOT_COVERAGE=smoke`, `NOT_AI=1`). Local P2
coverage is live keyboard, not VF6-WP5 fairness.

## Overlay leak (WP1 nit)

Win/lose/tie are CanvasLayers. Every title, lobby, rematch, or new
fight bumps a result token and calls `hide_result()`, so a deferred
result show cannot cover the title after rematch.

## Official path

No teleport. No `force_kill`. No editor clicks. Window E2E uses
viewport button activation plus `parse_input_event`. `apply_frames`
may step the sim after typed events.
