from pathlib import Path

root = Path(
    r"d:\dataDiskD\intellji\hoanhaosocial\hoanhaonew-20-6-2025\hh-game-studio\godot\dogfood\superfighters"
)
rows: list[tuple[str, str, str]] = []
for path in sorted(root.rglob("*.gd")):
    if ".godot" in path.parts:
        continue
    text = path.read_text(encoding="utf-8")
    cname = ""
    base = "RefCounted"
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("class_name "):
            cname = stripped.split()[1]
        elif stripped.startswith("extends ") and cname:
            base = stripped.split()[1]
            break
    if cname:
        rel = "res://" + path.relative_to(root).as_posix()
        rows.append((cname, base, rel))
rows.sort()
out = root / ".godot" / "global_script_class_cache.cfg"
out.parent.mkdir(parents=True, exist_ok=True)
chunks = []
for cname, base, rel in rows:
    chunks.append(
        "{\n"
        f'"base": &"{base}",\n'
        f'"class": &"{cname}",\n'
        '"icon": "",\n'
        '"is_abstract": false,\n'
        '"is_tool": false,\n'
        '"language": &"GDScript",\n'
        f'"path": "{rel}"\n'
        "}"
    )
out.write_text("list=[" + ", ".join(chunks) + "]\n", encoding="utf-8")
print(f"wrote {len(rows)} classes bytes={out.stat().st_size}")
for needle in ("MatchRules", "TieScreen", "MatchCases", "App", "GameSession"):
    print(needle, any(row[0] == needle for row in rows))
