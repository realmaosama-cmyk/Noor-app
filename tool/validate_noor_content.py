#!/usr/bin/env python3
"""Validate all bundled NOOR JSON files and strictly audit curated NOOR packs.

Legacy datasets are heterogeneous by design: structural inconsistencies are reported
as warnings so migration can be incremental. Curated NOOR packs are held to a strict
schema. No content is marked religiously verified by this script.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "legacy_content/assets/content")
CURATED = sorted(ROOT.glob("noor_*.json"))
ALL_JSON = sorted(ROOT.rglob("*.json"))
if not ALL_JSON:
    raise SystemExit(f"No JSON files found under {ROOT}")

errors = []
warnings = []
ids = set()
title_keys = set()
curated_lessons = 0
legacy_objects = 0
religious_sections = {"noor_quran.json", "noor_prayer.json", "noor_adhkar.json",
                      "noor_seerah.json", "noor_figures.json", "noor_prophets.json"}

def norm(value):
    value = value.strip().lower()
    value = re.sub(r"[ًٌٍَُِّْـ]", "", value)
    return re.sub(r"\s+", " ", value)

def candidate_lists(data):
    if isinstance(data, dict):
        for key in ("lessons", "hadiths", "games", "surahs", "ayat", "verses", "challenges"):
            value = data.get(key)
            if isinstance(value, list):
                yield from (item for item in value if isinstance(item, dict))
        if data.get("title") or data.get("name"):
            yield data
    elif isinstance(data, list):
        yield from (item for item in data if isinstance(item, dict))

for path in ALL_JSON:
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:
        errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
        continue

    items = list(candidate_lists(data))
    if not items:
        warnings.append(f"{path.relative_to(ROOT)}: no recognized lesson records (check parser support)")
    legacy_objects += len(items)
    if path not in CURATED:
        for index, item in enumerate(items, 1):
            if not (item.get("title") or item.get("name")):
                warnings.append(f"{path.name} record {index}: missing title/name")
        continue

    if not isinstance(data, dict) or data.get("schema") != 1 or not isinstance(data.get("lessons"), list) or not data["lessons"]:
        errors.append(f"{path.name}: expected schema=1 and a non-empty lessons array")
        continue

    for index, lesson in enumerate(data["lessons"], 1):
        label = f"{path.name} lesson {index}"
        curated_lessons += 1
        if not isinstance(lesson, dict):
            errors.append(f"{label}: record must be an object")
            continue

        lesson_id = lesson.get("id")
        if not isinstance(lesson_id, str) or not lesson_id.strip():
            errors.append(f"{label}: missing id")
        elif lesson_id in ids:
            errors.append(f"{label}: duplicate id {lesson_id}")
        else:
            ids.add(lesson_id)

        for field in ("title", "summary", "body", "source", "category", "difficulty"):
            if not isinstance(lesson.get(field), str) or not lesson[field].strip():
                errors.append(f"{label}: missing {field}")

        low, high = lesson.get("minAge"), lesson.get("maxAge")
        if type(low) is not int or type(high) is not int or low < 3 or high > 12 or low > high:
            errors.append(f"{label}: invalid age range {low!r}..{high!r}")

        steps = lesson.get("steps")
        if not isinstance(steps, list) or not steps:
            errors.append(f"{label}: steps must be a non-empty list")
        elif any(not ((isinstance(step, str) and step.strip()) or
                      (isinstance(step, dict) and any(isinstance(v, str) and v.strip()
                       for k, v in step.items() if k in {"text", "instruction", "label", "title", "prompt", "say"})))
                 for step in steps):
            errors.append(f"{label}: each step must be readable text or a supported step object")

        if lesson.get("content_verified") is not False:
            errors.append(f"{label}: content_verified must remain false until human review")
        if lesson.get("review_status") not in {"pending", "in_review", "approved"}:
            errors.append(f"{label}: review_status must be explicit")

        source = lesson.get("source", "")
        if re.search(r"مصدر\s+(موثوق|تاريخي\s+موثوق)|مصادر?\s+موثوقة", source, re.I):
            errors.append(f"{label}: vague source placeholder is not an acceptable citation")
        if path.name in religious_sections and lesson.get("review_status") != "approved":
            warnings.append(f"{label}: religious review still pending; do not present as verified")
        if lesson.get("review_status") == "approved" and lesson.get("content_verified") is not True:
            errors.append(f"{label}: approved review requires content_verified=true")

        duplicate_title = (norm(lesson.get("title", "")), low, high)
        if duplicate_title in title_keys:
            errors.append(f"{label}: duplicate title for the same age range")
        title_keys.add(duplicate_title)

if errors:
    print("ERRORS:")
    print("\n".join(errors))
    print(f"\nScanned {len(ALL_JSON)} JSON files; {legacy_objects} legacy records; {curated_lessons} curated lessons.")
    raise SystemExit(1)

print(f"Validated {len(ALL_JSON)} JSON files; inspected {legacy_objects} legacy records and {len(CURATED)} curated packs / {curated_lessons} lessons.")
if warnings:
    print(f"REVIEW WARNINGS ({len(warnings)}):")
    for warning in warnings:
        print(f"- {warning}")
