# Assumptions — R8-WP6 recreation

Run: `01R8WP6REC00000000KBA00001`

Filled from plan §6.2 (Godot 4.7.1-stable conventions, easiest to test,
fewest dependencies, then player-facing quality). Not E1–E4.

1. Relic-reached stays the only win flag. Recreation does not assign
   `relic_reached = true`.
2. Fresh-project emit means two empty Godot trees written from the
   baked snapshot/template plus `PROJECT_BRIEF.md` + `ASSET_MANIFEST.json`
   pin bytes. This is not a brief→game compiler. RECREATE stays
   unproven. Pin bytes are copied from the pin root, not a dogfood
   `src/` walk. Destination may live under `.hh-agent/evidence/…`.
   Two generated trees must hash-equal. Extra WP3–WP5 files
   (`run_art.gd` / `run_polish.gd` / `run_playtest.gd` / `*.tres`)
   are legal if present and not required this pass.
3. TREE of generated sources is evidence. HASHES stays unproven because
   the Windows review exe sha is not pinned across leftover-0 official
   runs. Artifact hashes are not claimed reproducible.
4. Official Python is not an independent critic and does not sign the
   rubric. CRITIC and RUBRIC stay unproven. HUMAN stays unproven.
   G5 stays [ ]. Do not fake dogfood. This PID does not play as the user.
5. Windowed `run_all.gd` on the fresh tree is plan §7.3 verify,
   not G5. It re-proves start→key→door→relic→win after recreate.
6. Windows export uses the already-pinned 4.7.1-stable tpz. Only
   x86_64 Windows templates are extracted. This is a review build,
   not R9 clean-VM / SBOM / store signing. `--provider plan` unused.
   No API key.
7. Official verify is
   `python tests/bootstrap/test_kho_bi_an_recreation.py` exit 0.
   Kill leftover Godot on kho-bi-an first. Sequential only.
8. If human review later fails quality, return to the named WP
   (R8-WP2..WP5). Do not open R9 because scripted boxes are green.
9. ColorRect Body nodes stay as invisible colliders. No snake
   demo. No secret material. GX stays [ ].
