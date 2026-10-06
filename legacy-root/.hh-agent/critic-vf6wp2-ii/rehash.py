from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import json

PACK = Path(r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters\tests\pack_vs_flow_evidence.py")
PRODUCT = PACK.parents[1]
FREEZE = PRODUCT / "docs/evidence/VF6WP2-20260901-ASIA-SAIGON-02/freeze.json"
CLAIM = "eaddfebe0fb320a2bd64a2df473dcccdd7fc42fcd13d3672bcf99a4699b0f5d6"

spec = spec_from_file_location("pack_vs_flow_evidence", PACK)
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
freeze = json.loads(FREEZE.read_text(encoding="utf-8"))
freeze_sha = freeze.get("files", {})
if not freeze_sha:
    freeze_sha = freeze.get("source_sha256", {})
mismatched = []
for rel, digest in sorted(source_sha.items()):
    fr = freeze_sha.get(rel)
    if fr != digest:
        mismatched.append(f"{rel} live={digest} freeze={fr}")
extra_freeze = sorted(set(freeze_sha) - set(source_sha))
missing_freeze = sorted(set(source_sha) - set(freeze_sha))
print(f"LIVE_TREE={source_tree}")
print(f"CLAIM_TREE={CLAIM}")
print(f"FREEZE_TREE={freeze.get('source_tree_sha256')}")
print(f"MATCH_CLAIM={int(source_tree == CLAIM)}")
print(f"MATCH_FREEZE={int(source_tree == freeze.get('source_tree_sha256'))}")
print(f"FILE_COUNT={len(source_sha)}")
print(f"FREEZE_COUNT={len(freeze_sha)}")
print(f"MISSING={','.join(missing) if missing else 'none'}")
print(f"MISMATCH_COUNT={len(mismatched)}")
print(f"EXTRA_FREEZE={len(extra_freeze)}")
print(f"MISSING_FREEZE={len(missing_freeze)}")
for row in mismatched[:20]:
    print(f"DRIFT {row}")
for row in extra_freeze[:10]:
    print(f"EXTRA {row}")
for row in missing_freeze[:10]:
    print(f"ABSENT {row}")
