#!/usr/bin/env python3
"""Freeze VF6-WP3 -01 source closure before official Godot."""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PRODUCT = REPO / "godot" / "dogfood" / "superfighters"
OUT = REPO / ".hh-agent" / "vf6wp3-20260901-01"
SAIGON = timezone(timedelta(hours=7))
SOURCE_SUFFIXES = {".gd", ".json", ".tscn", ".md"}
SOURCE_ROOTS = ("src", "data", "scenes")
SOURCE_EXTRA = (
    "tests/stage_cases.gd",
    "tests/run_stage.gd",
    "tests/check_stage.py",
    "tests/pack_stage_evidence.py",
    "tests/run_all.gd",
    "tests/vs_flow_cases.gd",
    "tests/match_cases.gd",
    "docs/stage.md",
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


def iter_source_files() -> tuple[str, ...]:
    found: set[str] = set(SOURCE_EXTRA)
    for root_name in SOURCE_ROOTS:
        root = PRODUCT / root_name
        if not root.is_dir():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in SOURCE_SUFFIXES:
                continue
            found.add(path.relative_to(PRODUCT).as_posix())
    return tuple(sorted(found))


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    source_sha = {}
    for rel in iter_source_files():
        path = PRODUCT / rel
        if not path.is_file():
            raise SystemExit(f"missing {rel}")
        source_sha[rel] = sha256_file(path)
    manifest_lines = [f"{digest}  {rel}" for rel, digest in sorted(source_sha.items())]
    tree = sha256_text("\n".join(manifest_lines) + "\n")
    payload = {
        "schema": "vault-fighters.freeze.v1",
        "run_id": "VF6WP3-20260901-ASIA-SAIGON-01",
        "command_id": "cmd.vf6-wp3.stage-progress.1",
        "wp": "VF6-WP3",
        "frozen_at": datetime.now(SAIGON).replace(microsecond=0).isoformat(),
        "file_count": len(source_sha),
        "source_tree_sha256": tree,
        "files": source_sha,
    }
    (OUT / "freeze.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    (OUT / "freeze.manifest").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")
    print(f"FREEZE file_count={len(source_sha)}")
    print(f"SOURCE_TREE={tree}")
    print(f"PATH={OUT / 'freeze.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
