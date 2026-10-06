#!/usr/bin/env python3
"""Independent VF6-WP2 remint -02 freeze hash recompute. Does not edit product."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

REPO = Path(r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio")
PRODUCT = REPO / "godot" / "dogfood" / "superfighters"
FREEZE = PRODUCT / "docs" / "evidence" / "VF6WP2-20260901-ASIA-SAIGON-02" / "freeze.json"
CLAIM = "eaddfebe0fb320a2bd64a2df473dcccdd7fc42fcd13d3672bcf99a4699b0f5d6"
SOURCE_SUFFIXES = {".gd", ".json", ".tscn", ".md"}
SOURCE_ROOTS = ("src", "data", "scenes")
SOURCE_EXTRA = (
    "tests/vs_flow_cases.gd",
    "tests/run_vs_flow.gd",
    "tests/check_vs_flow.py",
    "tests/pack_vs_flow_evidence.py",
    "tests/run_all.gd",
    "tests/match_cases.gd",
    "docs/vs_flow.md",
    "docs/match.md",
    "docs/reference-ledger.md",
    "KNOWN_ISSUES.md",
    "PROJECT_BRIEF.md",
    "project.godot",
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def iter_source_files(product: Path) -> tuple[str, ...]:
    found: set[str] = set(SOURCE_EXTRA)
    for root_name in SOURCE_ROOTS:
        root = product / root_name
        if not root.is_dir():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in SOURCE_SUFFIXES:
                continue
            found.add(path.relative_to(product).as_posix())
    return tuple(sorted(found))


def main() -> int:
    freeze = json.loads(FREEZE.read_text(encoding="utf-8"))
    source_sha: dict[str, str] = {}
    missing: list[str] = []
    for rel in iter_source_files(PRODUCT):
        path = PRODUCT / rel
        if path.is_file():
            source_sha[rel] = sha256_file(path)
        else:
            missing.append(rel)
    manifest_lines = [f"{digest}  {rel}" for rel, digest in sorted(source_sha.items())]
    now = sha256_text("\n".join(manifest_lines) + "\n")
    freeze_tree = str(freeze.get("source_tree_sha256", ""))
    freeze_files = freeze.get("files", {})
    drift: list[str] = []
    extra_now = sorted(set(source_sha) - set(freeze_files))
    extra_freeze = sorted(set(freeze_files) - set(source_sha))
    for rel, digest in sorted(source_sha.items()):
        old = str(freeze_files.get(rel, ""))
        if old and old != digest:
            drift.append(rel)
    out = {
        "claim": CLAIM,
        "freeze_tree": freeze_tree,
        "now_tree": now,
        "match_claim": now == CLAIM,
        "match_freeze": now == freeze_tree,
        "file_count_now": len(source_sha),
        "file_count_freeze": len(freeze_files),
        "missing": missing,
        "drift_files": drift[:40],
        "extra_now": extra_now[:40],
        "extra_freeze": extra_freeze[:40],
    }
    dest = Path(__file__).with_name("rehash.json")
    dest.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(out, indent=2))
    return 0 if now == CLAIM and now == freeze_tree and not missing and not drift else 1


if __name__ == "__main__":
    raise SystemExit(main())
