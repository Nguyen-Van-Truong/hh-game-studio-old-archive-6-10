import hashlib
from pathlib import Path
import sys
sys.path.insert(0, r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters\tests")
from pack_sewer_evidence import SOURCE_FILES, sha256_file, sha256_text

product = Path(r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters")
freeze_path = Path(r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\vf5wp5-07\source_freeze.txt")
run_path = product / "docs/evidence/VF5WP5-20260831-ASIA-SAIGON-07/run.json"
import json
run = json.loads(run_path.read_text(encoding="utf-8"))
claimed = run["source_tree_sha256"]
packed_sha = run["source_sha256"]

freeze_sha = {}
for line in freeze_path.read_text(encoding="utf-8").splitlines():
    if "  " in line and not line.startswith("#") and not line.startswith("frozen") and not line.startswith("run_") and not line.startswith("command") and not line.startswith("base_") and not line.startswith("source_") and not line.startswith("note="):
        digest, rel = line.split("  ", 1)
        if len(digest) == 64:
            freeze_sha[rel.strip()] = digest

source_sha = {}
mismatch = []
for rel in SOURCE_FILES:
    path = product / rel
    digest = sha256_file(path)
    source_sha[rel] = digest
    fr = freeze_sha.get(rel)
    pk = packed_sha.get(rel)
    flags = []
    if fr and fr != digest:
        flags.append("NE_FREEZE")
    if pk and pk != digest:
        flags.append("NE_PACK")
    if fr is None:
        flags.append("NO_FREEZE")
    if pk is None:
        flags.append("NO_PACK")
    if flags:
        mismatch.append(f"{rel} {' '.join(flags)} now={digest} freeze={fr} pack={pk}")

manifest_lines = [f"{digest}  {rel}" for rel, digest in sorted(source_sha.items())]
tree = sha256_text("\n".join(manifest_lines) + "\n")
print(f"PY_SOURCE_TREE={tree}")
print(f"CLAIM={claimed}")
print(f"MATCH={tree == claimed}")
print(f"FILE_COUNT={len(source_sha)} FREEZE_COUNT={len(freeze_sha)} PACK_COUNT={len(packed_sha)}")
print(f"MISMATCH_COUNT={len(mismatch)}")
for row in mismatch:
    print(row)
if not mismatch:
    print("ALL_FILE_HASHES_MATCH_FREEZE_AND_PACK")
