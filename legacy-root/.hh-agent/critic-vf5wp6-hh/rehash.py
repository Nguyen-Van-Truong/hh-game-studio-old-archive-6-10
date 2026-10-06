#!/usr/bin/env python3
"""Critic-only source-tree rehash. Does not edit product."""
from __future__ import annotations

import hashlib
from pathlib import Path

PRODUCT = Path(
    r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio"
    r"\godot\dogfood\superfighters"
)
CLAIMED = "771fdc8445b5e814c1827a1d938e0202a2d6dad9543219f01038bc244206698a"
SOURCE_FILES = (
    "src/maps/arena_spec.gd",
    "src/maps/map_catalog.gd",
    "src/maps/map_graph.gd",
    "src/maps/map_codec.gd",
    "src/maps.gd",
    "src/arena.gd",
    "src/app.gd",
    "src/ui/title_screen.gd",
    "src/hud.gd",
    "src/sim/sim_constants.gd",
    "src/world/env_body.gd",
    "src/world/world_owner.gd",
    "src/game_session.gd",
    "data/maps/schema.json",
    "data/maps/catalog.json",
    "data/maps/arena_spec.json",
    "data/maps/arenas/hazardous.json",
    "data/maps/arenas/police.json",
    "data/maps/arenas/storage.json",
    "data/maps/arenas/rooftops.json",
    "data/maps/arenas/lantern.json",
    "data/maps/arenas/gauge.json",
    "data/world/catalog.json",
    "data/world/moving.json",
    "data/world/env.json",
    "tests/vs_roster_cases.gd",
    "tests/run_vs_roster.gd",
    "tests/check_vs_roster.py",
    "tests/pack_vs_roster_evidence.py",
    "tests/_gen_vs_arenas.py",
    "tests/map_cases.gd",
    "tests/run_all.gd",
    "docs/vs_roster.md",
    "docs/lantern.md",
    "docs/gauge.md",
    "docs/provenance.md",
    "docs/maps.md",
    "docs/world.md",
    "docs/env.md",
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


def main() -> int:
    source_sha: dict[str, str] = {}
    for rel in SOURCE_FILES:
        path = PRODUCT / rel
        if path.is_file():
            source_sha[rel] = sha256_file(path)
        else:
            print(f"MISSING {rel}")
    manifest_lines = [f"{digest}  {rel}" for rel, digest in sorted(source_sha.items())]
    tree = hashlib.sha256(("\n".join(manifest_lines) + "\n").encode("utf-8")).hexdigest()
    print(f"SOURCE_TREE={tree}")
    print(f"CLAIMED={CLAIMED}")
    print(f"MATCH={tree == CLAIMED}")
    print(f"FILE_COUNT={len(source_sha)}")
    return 0 if tree == CLAIMED else 1


if __name__ == "__main__":
    raise SystemExit(main())
