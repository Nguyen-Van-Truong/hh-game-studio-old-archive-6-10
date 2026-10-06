#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAN = ROOT / "godot/dogfood/superfighters/assets/ASSET_MANIFEST.json"
MAPS = ROOT / "godot/dogfood/superfighters/src/maps.gd"


def hash_check() -> None:
    man = json.loads(MAN.read_text(encoding="utf-8"))
    ok = 0
    bad = []
    missing = []
    for rec in man["files"]:
        p = ROOT / rec["path"]
        if not p.is_file():
            missing.append(rec["path"])
            continue
        h = hashlib.sha256(p.read_bytes()).hexdigest()
        if h != rec["sha256"]:
            bad.append((rec["path"], rec["sha256"], h))
        else:
            ok += 1
    print(
        "manifest_ok",
        ok,
        "mismatch",
        len(bad),
        "missing",
        len(missing),
        "total",
        len(man["files"]),
    )
    for path, exp, act in bad:
        print("MISMATCH", path)
        print("  expected", exp)
        print("  actual  ", act)
    for path in missing:
        print("MISSING", path)


def extract(text: str, name: str) -> list[str]:
    m = re.search(
        rf"static func _{name}\(\) -> PackedStringArray:.*?return PackedStringArray\(\[(.*?)\]\)",
        text,
        re.S,
    )
    if not m:
        return []
    return re.findall(r'"([^"]*)"', m.group(1))


def map_hunt() -> None:
    text = MAPS.read_text(encoding="utf-8")
    for name in ["rooftops", "storage", "police", "hazardous"]:
        rows = extract(text, name)
        h = len(rows)
        w = len(rows[0]) if rows else 0
        official = 0
        if h >= 2:
            for x in range(w):
                if rows[h - 1][x] == "." and rows[h - 2][x] == ".":
                    official += 1
        empty = []
        for x in range(w):
            if all(rows[y][x] not in "#cb=" for y in range(h)):
                empty.append(x)
        print(
            f"MAP {name} {w}x{h} pit_column_count={official} "
            f"true_empty_cols={len(empty)} empty_x={empty[:24]}"
        )
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch in "P12":
                    under = [rows[y + dy][x] for dy in range(1, 8) if y + dy < h]
                    print(f"  spawn {ch} @({x},{y}) under={''.join(under)}")
        if name == "police":
            print("  row11", rows[11])
            print("  row12", rows[12])
            print("  row13", rows[13])
            print("  interior22-45_row12", rows[12][22:46])
            badc = [x for x in range(21, 47) if rows[12][x] != "#"]
            print("  interior_nonhash_x", badc)
            for x in range(w):
                if rows[11][x] in ".P12Hw" and rows[12][x] not in "#cb=" and rows[13][x] not in "#cb=":
                    print(
                        f"  GROUND_HOLE x={x} r11={rows[11][x]} "
                        f"r12={rows[12][x]} r13={rows[13][x]}"
                    )


if __name__ == "__main__":
    hash_check()
    map_hunt()
