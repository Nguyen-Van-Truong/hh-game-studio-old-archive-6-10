from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import json
import hashlib

PACK = Path(r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters\tests\pack_vs_flow_evidence.py")
PRODUCT = PACK.parents[1]
FREEZE = PRODUCT / "docs/evidence/VF6WP2-20260901-ASIA-SAIGON-03/freeze.json"
CLAIM = "81c44f5bbe9a4c16c3fdd8599147309edc550228bdec79ed00a5fddcb8d3f55b"
GODOT = Path.home() / "AppData/Local/HHGodotAgent/tooling/godot-4.7.1-stable/bin/Godot_v4.7.1-stable_win64_console.exe"
CLAIM_GODOT = "35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef"
OUT = Path(r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\.hh-agent\critic-vf6wp2-ii-03\rehash.json")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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
        mismatched.append({"rel": rel, "live": digest, "freeze": fr})
extra_freeze = sorted(set(freeze_sha) - set(source_sha))
missing_freeze = sorted(set(source_sha) - set(freeze_sha))
godot_hash = sha256_file(GODOT) if GODOT.is_file() else ""
payload = {
    "live_tree": source_tree,
    "claim_tree": CLAIM,
    "freeze_tree": freeze.get("source_tree_sha256"),
    "match_claim": source_tree == CLAIM,
    "match_freeze": source_tree == freeze.get("source_tree_sha256"),
    "file_count": len(source_sha),
    "freeze_count": len(freeze_sha),
    "missing": missing,
    "mismatch_count": len(mismatched),
    "mismatched": mismatched[:20],
    "extra_freeze": extra_freeze,
    "missing_freeze": missing_freeze,
    "godot_hash": godot_hash,
    "godot_match": godot_hash == CLAIM_GODOT,
    "godot_exists": GODOT.is_file(),
}
OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
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
print(f"GODOT_HASH={godot_hash}")
print(f"GODOT_MATCH={int(godot_hash == CLAIM_GODOT)}")
for row in mismatched[:20]:
    print(f"DRIFT {row['rel']} live={row['live']} freeze={row['freeze']}")
for row in extra_freeze[:10]:
    print(f"EXTRA {row}")
for row in missing_freeze[:10]:
    print(f"ABSENT {row}")
