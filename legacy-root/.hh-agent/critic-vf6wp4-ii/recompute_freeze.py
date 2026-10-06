#!/usr/bin/env python3
"""Critic II freeze recompute. Does not edit product."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

SOURCE_SUFFIXES = {".gd", ".json", ".tscn", ".md"}
SOURCE_ROOTS = ("src", "data", "scenes")
SOURCE_EXTRA = (
    "tests/survival_cases.gd",
    "tests/run_survival.gd",
    "tests/check_survival.py",
    "tests/pack_survival_evidence.py",
    "tests/run_all.gd",
    "tests/stage_cases.gd",
    "tests/match_cases.gd",
    "docs/survival.md",
    "docs/stage.md",
    "docs/match.md",
    "docs/vs_flow.md",
    "docs/reference-ledger.md",
    "KNOWN_ISSUES.md",
    "PROJECT_BRIEF.md",
    "project.godot",
)
CLAIMED = "4fb78a4c6875649e16797115d711d3739f371348d437c665180755e99b6890ec"


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
    product = Path(sys.argv[1])
    freeze_path = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    source_sha = {}
    missing = []
    source_list = iter_source_files(product)
    for rel in source_list:
        path = product / rel
        if path.is_file():
            source_sha[rel] = sha256_file(path)
        else:
            missing.append(rel)
    manifest_lines = [f"{digest}  {rel}" for rel, digest in sorted(source_sha.items())]
    tree = sha256_text("\n".join(manifest_lines) + "\n")
    print(f"FILE_COUNT={len(source_sha)}")
    print(f"MISSING={len(missing)}")
    if missing:
        print("MISSING_FILES=" + ",".join(missing[:12]))
    print(f"SOURCE_TREE={tree}")
    print(f"CLAIMED={CLAIMED}")
    print(f"MATCH={str(tree == CLAIMED).lower()}")
    if freeze_path and freeze_path.is_file():
        freeze = json.loads(freeze_path.read_text(encoding="utf-8"))
        freeze_files = freeze.get("files", {})
        print(f"FREEZE_COUNT={freeze.get('file_count')}")
        print(f"FREEZE_TREE={freeze.get('source_tree_sha256')}")
        drifted = []
        extra = []
        for rel, digest in sorted(source_sha.items()):
            old = freeze_files.get(rel)
            if old is None:
                extra.append(rel)
            elif old != digest:
                drifted.append(rel)
        vanished = [rel for rel in freeze_files if rel not in source_sha]
        print(f"DRIFTED={len(drifted)}")
        print(f"EXTRA={len(extra)}")
        print(f"VANISHED={len(vanished)}")
        for rel in drifted[:20]:
            print(f"  drift {rel}")
        for rel in extra[:20]:
            print(f"  extra {rel}")
        for rel in vanished[:20]:
            print(f"  vanished {rel}")
    return 0 if tree == CLAIMED and not missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
