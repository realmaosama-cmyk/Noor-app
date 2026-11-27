#!/usr/bin/env python3
"""Validate curated NOOR JSON lesson packs without modifying source data."""
import json
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else "legacy_content/assets/content")
packs = sorted(root.glob("noor_*.json"))
if len(packs) != 9:
    raise SystemExit(f"Expected 9 curated NOOR packs, found {len(packs)}")

seen = set()
lesson_count = 0
errors = []
for path in packs:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{path.name}: invalid JSON: {exc}")
        continue
    lessons = data.get("lessons")
    if data.get("schema") != 1 or not isinstance(lessons, list) or not lessons:
        errors.append(f"{path.name}: schema/lessons missing")
        continue
    for index, lesson in enumerate(lessons, 1):
        label = f"{path.name} lesson {index}"
        lesson_id = lesson.get("id")
        if not isinstance(lesson_id, str) or not lesson_id.strip():
            errors.append(f"{label}: missing id")
        elif lesson_id in seen:
            errors.append(f"{label}: duplicate id {lesson_id}")
        else:
            seen.add(lesson_id)
        for field in ("title", "summary", "body", "source"):
            if not isinstance(lesson.get(field), str) or not lesson[field].strip():
                errors.append(f"{label}: missing {field}")
        low, high = lesson.get("minAge"), lesson.get("maxAge")
        if not isinstance(low, int) or not isinstance(high, int) or low < 3 or high > 12 or low > high:
            errors.append(f"{label}: invalid age range {low!r}..{high!r}")
        steps = lesson.get("steps")
        if not isinstance(steps, list) or not steps or any(not isinstance(x, str) or not x.strip() for x in steps):
            errors.append(f"{label}: steps must be a non-empty list of strings")
        lesson_count += 1

if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print(f"Validated {len(packs)} curated NOOR packs and {lesson_count} lessons.")
