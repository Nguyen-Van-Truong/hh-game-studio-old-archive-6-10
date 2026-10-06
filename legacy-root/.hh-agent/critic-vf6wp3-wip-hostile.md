WIP_TICK=no

CRITIC=hostile-read-only (cursor-grok-4.6-xhigh-fast)
DATE=2026-09-03
SCOPE=VF6-WP3 remint WIP (not official leftover-0)
HEAD=c1a7b11769fbf4fd57c1e9da2e9748e2ece6c0ff
WP2_TRUSTED=5ab444a / 147331d (147331d is ancestor of HEAD)
29-8=31/50 CURRENT_VALID_WP=VF6-WP3 still [ ]
PARENT_20-8=59/60 R9-WP4 [ ] G6 [ ] GX [ ] (not edited)
OFFICIAL_-01=VOID (II yes / HH no on ddb82205…)
OFFICIAL_-02=ABSENT (no docs/evidence/VF6WP3-20260901-ASIA-SAIGON-02/)
LEFTOVER_GODOT=0 (process list; no run_all / run_stage launched)
CHECK_STAGE=structure PASS only (python tests/check_stage.py exit 0). Not leftover-0 official Godot.
NO_TICK=1 NO_COMMIT=1 NO_PLAN_EDIT=1

Protocol: two leftover-0 critics TICK=yes on the same new frozen hash are required
to tick. This file is a WIP hunt, not that pair. Do not tick. Do not start VF6-WP4.

================================================================================
VERDICT
================================================================================

WIP is not READY_FOR_CRITICS. Coordinator claims about bak+tmp, fail-closed
record_win, two-click Reset, and VS-vs-Stage labels are partly true in source
and still unproved on an official leftover-0 pack. The police catalog win is
still the official blocker. FEEDBACK/outcome "pass" is harness language, not
user sentiment.

================================================================================
MUST-FIX BEFORE OFFICIAL `-02` (ranked)
================================================================================

1. Police catalog win: 3 live bots + wall tile 25  [OFFICIAL BLOCKER]

   DoD: win police on catalog geometry, then load hazardous. Packer now
   requires after_win2_map==hazardous and win_rows include police (not
   fx_melee_close). No -02 pack exists. This critic did not run Godot hunt.

   Geometry: police.json solid column x=25, y=5..9 (and floor 25,12/13).
   Hunt hardcodes wall_x=400.0 (tile 25 * 16).

   Roster: StageRules bots=3. game_session spawns P1 at _spawn_at(0), bots
   at _spawn_at(1..3). Arena only has slots 0,1,2:
     (4,7) P1 left; (14,9) mid-left of wall; (59,7) far right.
   Bot 3 overflows: last spawn + Vector2(3*24, 0) ≈ right edge / off walkable.
   Closest living foe after start is the left bot (~tile 14). _police_intent
   then stays left ("do not drop to the ground wall at x≈395") until that
   bot dies. The two right-court bots sit behind tile 25. Crossing is a
   scripted run-jump / stuck>18 ram. That is the 394.8 / 238.5 pin from the
   2-9 handoff diag. This workspace has no .hh-agent/vf6wp3-02-diag/.

   LOAD can still count 3 is_bot (overflow body counts). That is not a win.
   Until a leftover-0 official run shows police death_cause on catalog
   geometry and AFTER2=hazardous, VF6-WP3 stays [ ].

2. App advances even when record_win fail-closes  [DoD skip / V-A13]

   stage.gd record_win: skip (won_index != current, not already) sets
   last_error and returns without persist. Good for the helper.

   app.gd _on_won ignores last_error and persist_atomic's return:
     StageRules.record_win(stage_index)
     if stage_index + 1 < count: _advance_stage()
   Live fight still increments stage_index and loads the next map.

   persist_atomic can return "" (bak park / rename / tmp leftover).
   record_win still mutates the in-memory dict first, then persist, then
   returns that dict anyway. Disk may stay on the old checkpoint while
   RAM campaign walks forward. Next record_win(1) against disk current=0
   fail-closes; _on_won still advances to 2. That is a skip.

   Cold Continue would load the stale save. Official Continue is written
   to be cold — this hole would fail it, or worse, pass Continue on the
   wrong index if RAM and disk diverge mid-pack.

3. Persist bak+tmp is real code, not a closed V-A13 proof

   Claim: park final→bak, write tmp, rename tmp→final; load final / tmp / bak.
   Source matches that shape. Crash windows still exist:

   - Successful persist DELETES .bak. After a clean write there is no bak.
     "load recovers bak" is only the mid-swap window (or a planted file).
   - reward_hash_stable plants bak itself (copy final → bak, delete final).
     That proves the load fallback, not that persist_atomic left a bak.
   - No fsync/flush before rename. Crash during tmp write can leave junk
     JSON; load_json returns {} and falls through. OK if bak still exists;
     after success bak is gone.
   - Windows: dest-exists rename. They delete bak first, then park. If bak
     delete fails (lock/AV) park fails, they delete the new tmp and abort.
     Mixed FileAccess.file_exists(user://) vs DirAccess.rename(abs).
   - After tmp→final OK they still fail if tmp leftover, but bak may
     already be deleted. Return "" while final already holds new bytes.
   - load does not recompute/verify reward_hash or schema_hash.

   Tests set outcome_hash AFTER skip + planted-bak (yes). They do not
   assert skip left awarded empty / score 0 / disk unchanged. They do not
   exercise Windows dest-exists or persist return="" .

4. Reset two-click is product-real; official proof is still ENTER fallback

   title_screen: first click arms "Confirm Reset"; second emits wipe.
   refresh_stage_caption() disarms. Good for a mouse user who reads.

   continue_and_reset calls _activate_button(reset) ONCE. Probe is score.
   First click does not change score → KEY_ENTER → ui_accept. Wipe happens
   inside one helper. Tests never assert button text "Confirm Reset" or two
   distinct clicks. A one-click Reset would still pass this path.

   Players: same button, no modal, no timeout. Double-click or Enter after
   focus still wipes. Stage click disarms; a confused player can still
   lose the campaign save.

5. Title VS Map vs Stage checkpoint — labeled, still easy to misread

   Stage button uses caption_for (Stage / Continue Stage / Stage cleared)
   and load_or_empty current_index. VS Map cycles Maps.next_vs_map (six
   VS ids, wrap, no unlock gate). Status says "VS Map below is VS only."

   After a Stage fight, restart_to_title does set_map_id(map_id) with the
   Stage map just played. The button can read "VS Map: Signal Court" after
   police even though that cycle does not move the Stage checkpoint.
   Same display names as campaign arenas. Status line is small brass text
   at y=568. Must-fix for -02 only if stills/status fail to show the
   split; otherwise quality (confusion).

6. Official leftover-0 pack still missing (protocol, not a code hunt)

   No freeze, no headless/window/run_all host exits, no events.jsonl, no
   stills, no leftover_proof for -02. -01 events were 0 bytes and
   title_after was a fight still. Code now requires timeline/events and
   title_after=title; none of that is proven on this HEAD WIP.
   check_stage.py PASS is string/schema only. Do not treat it as E2E.

7. Win path still accepts non-damage death_cause  [V-A16 residual]

   _catalog_resolve: lose requires death_cause==damage. Win allows any
   non-empty cause. Pit-KO of the last bot can count as a catalog "win".
   Packer does not require win death_cause==damage. Loss overlay still
   maps reasons through "Down" / p1_down style copy. Do not ship -02
   with pit-as-win or pit-as-loss.

================================================================================
QUALITY LATER (not a VF6-WP3 tick)
================================================================================

8. Unlocks are bookkeeping. Fair for the WP3 letter if labeled.

   persist unlock strings ("storage" / "police" / "hazardous") and show
   "last unlock …" on the title status. VS cycle stays free. Stage gating
   is current_index, not unlocks. The unlock name is the next map you
   already reached. Documented in docs/stage.md. Do not claim a lock.
   Fake "unlock" copy is quality / VF7, not a tick blocker if honest.

9. FEEDBACK=pass / outcome pass ≠ user sentiment

   Stage banners have no FEEDBACK row (VS2 does). SCHEMA/LOAD/ADVANCE/…
   verdict=pass is a harness bit. User-hate risks that must not be laundered
   into a tick:

   - Dumb bots: NOT_AI=1, BOT_COVERAGE=smoke, fairness is VF6-WP5.
   - Prototype HUD / title wall of hints: VF7-WP3.
   - Thin maps: police hazard=[] prop=[]; third bot overflow spawn.
   - Reset wipe (two-click or not) destroys score/unlocks.
   - No Survival: VF6-WP4, survival_shipped=false. Correct for this WP.

10. Mid-campaign has no win overlay. _on_won deferred-advances until the
    last arena. Player never sees a "stage clear" beat except hazardous.
    Quality / VF7.

11. Art, audio, bot tactics stay VF7 / VF6-WP5. Tiers stay approximation.
    Title remains Vault Fighters. No Y8 rip.

================================================================================
COORDINATOR CLAIMS — VERIFY TABLE
================================================================================

| # | Claim | Held? |
|---|---|---|
| 1 | persist is bak+tmp recover (V-A13) | Partial. Code path exists. Success deletes bak. Tests plant bak. persist return ignored. Windows dest-exists / no fsync still open. |
| 2 | record_win fail-closed | Partial. Skip helper fail-closes. Duplicate does not add score. App still advances; persist fail is not fail-closed. Tests set outcome_hash after skip/bak (true) but do not prove disk-unchanged on skip. |
| 3 | Title VS Map vs Stage; Reset two-click | Partial. Labels exist. After Stage, VS Map text can show the Stage map. Reset two-click exists; official helper still ENTER-completes in one call. |
| 4 | Unlocks bookkeeping; VS cycle free | Held as designed. Fair if not claimed as a lock. |
| 5 | Police hunt cannot KO 3 live bots / cross tile 25 | Held. Official blocker. Overflow 4th spawn index. No -02 proof. |
| 6 | FEEDBACK=pass is not user sentiment | Held. Do not tick on quality. |

================================================================================
WHAT STILL LOOKS HONEST (do not regress)
================================================================================

- 29-8 VF6-WP3 checkbox still [ ]. Parent 59/60 untouched by this critic.
- Title card "Vault Fighters". y8_parity_claimed / y8_order_observed false.
  order_class / difficulty_class approximation. Survival unshipped.
- Harness forbids fx_melee_close, apply_eval, force_kill, teleport, pit loss.
- Packer requires after_win0/1/2 = storage/police/hazardous, cold Continue
  on hazardous, leftover-0 + console twin + FINISHED=1 (not PASS-as-exit).
- Isolated LOAD still wants live is_bot 1/2/3/3. Reward hash is
  StageRules.compute_hash, not a pasted hex in check_stage.py.
- Trusted WP2 pair 5ab444a / 147331d. Do not redo WP1/WP2.

================================================================================
DO NOT
================================================================================

- Tick 29-8. Do not start VF6-WP4. Do not edit 20-8 / AGENTS.md.
- Reuse VF6WP3-20260901-ASIA-SAIGON-01 or cmd.vf6-wp3.stage-progress.1.
- Treat this file, check_stage.py PASS, or leftover-0 process list as
  official leftover-0 critic TICK=yes.
- Average with any later "yes" until a new freeze + official pack exists.

HẾT
