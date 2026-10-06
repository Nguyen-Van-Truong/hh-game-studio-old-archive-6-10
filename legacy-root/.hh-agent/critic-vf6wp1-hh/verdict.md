# Hostile Critic HH — VF6-WP1 remint `-03`

**TICK=no**

Product not edited. Plan not ticked. No commit. VF6-WP2 not started. No Y8 rip.
Independent leftover-0 iso: `.hh-agent/critic-vf6wp1-hh/iso`

## Quoted Verify / DoD (current 29-8 VF6-WP1)

Verify: real typed input traces plus real window/menu/input E2E for
win/loss/tie/quit/restart/pause; no direct `apply_eval`, private method,
synthetic `.pressed.emit()` or `force_kill` may be the sole proof. Pause
must not advance sim. Host captures actual Godot process exits; a banner,
caller-supplied exit integer, stale package or killed/hung process is FAIL.

DoD: one canonical match state machine used by every mode.

## TICK=no gates

1. **Windowed leftover-0 hung (hunts 1–2).** Frozen source
   `de9f28b7dcea25fbd3e550cc86f565b153fbf4b38189101ba16698a458895c6c`.
   GUI `Godot_v4.7.1-stable_win64.exe` + `Start-Process -Wait` on the HH
   iso wrote `match_setup` at 14:55:13 then produced no further stills,
   outcomes, or `run_partial` for 632s. Independent host exit after kill
   is **-1**, not 0. Pack `leftover_proof.json` / `exits_proof.json` are
   caller-written; packer `parse_exit_from_log` treats a PASS banner as
   exit 0 and does not parse `run_all` host exit. Verify: hung/killed
   process is FAIL. Headless on the same iso did exit 0 in 146s leftover-0,
   so the suite can finish without a window — that does not prove the
   claimed window leftover-0.

2. **DoD: one machine is not used by every mode (hunt 3).**
   `MACHINE=pass` lists `vs1, vs2, stage, survival`. Survival is
   `shipped: false`, has no title button, and `app.gd` never calls
   `start_fight("survival")`. Official traces are vs2 only (lose is
   rooftops vs2). Stage is a title/start path with no official
   win/lose/tie/quit/pause trace. vs1 appears only as an FF melee
   setup on `fx_melee_close` after forcing `bot.team = p1.team`.
   JSON `uses_machine` flags are not use.

3. **Verify menu/input E2E is not the proof for win/lose/tie/restart.**
   Those four official rows are `apply_frames` traces. Window stills are
   photographs after those traces. Official pause is `match_ops` →
   `session.set_paused` (private). Official quit is `match_ops` →
   `request_quit`. `_shot_quit` always calls `app.quit_to_title()` after
   the click; `_on_quit_match` returns immediately when `test_driven`.
   LIVE records `title_visible_after=false`. `apply_eval` remains the
   SIGNAL harness. push_input Quit is not a complete player path to title.

4. **`run_all` leftover-0 not independently proven (hunt 4).** Packed
   `run_all.headless.log` is 32 banners including DIVE 1253/1253, VS
   roster, and SEWER 4793/4793, then `PASS: Vault Fighters first playable`.
   No Godot quit footer. Packer accepts that banner set as `run_all_ok`.
   HH did not launch a second `run_all` (Critic II already held
   `critic-vf6wp1-ii/iso`). Banner theater remains unrefuted.

## What held (not enough for TICK=yes)

- HEAD `2b1e0a2`. VF6-WP1 still `[ ]`. 29/50. 31-8 `AUTHORITY=0`.
- Source tree recomputed **match** freeze/run/now. `hashes.txt` 141/141.
  Eight packed stills pairwise-distinct and hash-match `run.json`.
- IDs are `-03` / `cmd.vf6-wp1.match-machine.3`; `-01`/`.1` and `-02`/`.2`
  were prior remints, not reused.
- Headless leftover-0 EXIT 0; replay hashes byte-match the pack; FF
  melee on `fx_melee_close` reports same-team blocked / cross-team damage;
  pause dual-clock apply+reject keeps sim tick 16 and hash
  `59c3c764…` while authored 16–31 (not a skip-the-frames no-op).
- No rematch UX sneak (win still is Restart). No Survival button. No
  VF7 art import. No ObjectDB in packed logs. No Superfighters title.
  Plan / parent 20-8 untouched.

## Player stills

Win/lose/tie/pause overlays exist. Tie is a 36-tick timeout with both
fighters at 100 HP (labeled approximation). Quit still is the title
after a forced `quit_to_title`, status “Last match ended: quit.”
Restart looks like a fresh vs2 spawn. HUD still shows debug
`HP ST G3 x0` (VF7, not this WP).

TICK=no
