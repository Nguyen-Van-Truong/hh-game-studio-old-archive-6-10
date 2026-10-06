from datetime import datetime, timedelta, timezone
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import json

SAIGON = timezone(timedelta(hours=7))
PACK = Path(
    r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters\tests\pack_match_evidence.py"
)
PRODUCT = PACK.parents[1]
OUT = Path(
    r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\vf6wp1-20260901-04\freeze.json"
)

spec = spec_from_file_location("pack_match_evidence", PACK)
mod = module_from_spec(spec)
spec.loader.exec_module(mod)
source_sha = {}
missing = []
for rel in mod.iter_source_files(PRODUCT):
    path = PRODUCT / rel
    if path.is_file():
        source_sha[rel] = mod.sha256_file(path)
    else:
        missing.append(rel)
manifest_lines = [f"{digest}  {rel}" for rel, digest in sorted(source_sha.items())]
source_tree = mod.sha256_text("\n".join(manifest_lines) + "\n")
OUT.parent.mkdir(parents=True, exist_ok=True)
payload = {
    "schema": "vault-fighters.vf6-wp1.freeze.v1",
    "run_id": mod.RUN_ID,
    "command_id": mod.COMMAND_ID,
    "frozen_at": datetime.now(SAIGON).replace(microsecond=0).isoformat(),
    "base_head": "2b1e0a2e8ff2e7b4b8bfa35080b7f551be091db8",
    "source_tree_sha256": source_tree,
    "file_count": len(source_sha),
    "source_sha256": source_sha,
    "missing": missing,
}
OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"FREEZE={source_tree}")
print(f"FILES={len(source_sha)}")
print(f"MISSING={','.join(missing) if missing else 'none'}")
print(f"RUN_ID={mod.RUN_ID}")
print(f"COMMAND_ID={mod.COMMAND_ID}")
print(f"PATH={OUT}")
