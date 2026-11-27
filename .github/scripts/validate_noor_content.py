#!/usr/bin/env python3
"""Validate every NOOR JSON asset; legacy variants warn, curated packs fail strictly."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "legacy_content/assets/content")
ALL_JSON = sorted(ROOT.rglob("*.json"))
CURATED = sorted(ROOT.glob("noor_*.json"))
if not ALL_JSON:
    raise SystemExit(f"No JSON files found under {ROOT}")

errors, warnings = [], []
ids, title_keys = set(), set()
legacy_records = curated_count = 0
religious = {"noor_quran.json", "noor_prayer.json", "noor_adhkar.json",
             "noor_seerah.json", "noor_figures.json", "noor_prophets.json"}

def norm(value):
    value = re.sub(r"[ًٌٍَُِّْـ]", "", value.strip().lower())
    return re.sub(r"\s+", " ", value)

def records(data):
    if isinstance(data, dict):
        found = False
        for key in ("lessons", "hadiths", "games", "surahs", "ayat", "verses", "challenges"):
            value = data.get(key)
            if isinstance(value, list):
                found = True
                yield from (item for item in value if isinstance(item, dict))
        if not found and (data.get("title") or data.get("name")):
            yield data
    elif isinstance(data, list):
        yield from (item for item in data if isinstance(item, dict))

for path in ALL_JSON:
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:
        errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
        continue

    items = list(records(data))
    if not items:
        warnings.append(f"{path.relative_to(ROOT)}: no recognized lesson records; parser support needs review")
    if path not in CURATED:
        legacy_records += len(items)
        continue

    if not isinstance(data, dict) or data.get("schema") != 1 or not isinstance(data.get("lessons"), list) or not data["lessons"]:
        errors.append(f"{path.name}: expected schema=1 and non-empty lessons")
        continue

    for index, lesson in enumerate(data["lessons"], 1):
        label = f"{path.name} lesson {index}"
        curated_count += 1
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
            errors.append(f"{label}: unsupported or empty step")

        if lesson.get("content_verified") is not False:
            errors.append(f"{label}: content_verified must remain false until human review")
        if lesson.get("review_status") not in {"pending", "in_review", "approved"}:
            errors.append(f"{label}: review_status must be explicit")
        if lesson.get("citation_status") not in {"needs_review", "verified"}:
            errors.append(f"{label}: citation_status must be explicit")

        source = lesson.get("source", "")
        vague = bool(re.search(
            r"^(?:مصدر|مرجع)\s+(?:موثوق|موثوقة|مقترح)|^كتب التراجم|^تراجم وسير موثوقة|^السيرة النبوية؛",
            source, re.I))
        if vague and lesson.get("review_status") == "approved":
            errors.append(f"{label}: generic source text cannot be approved as a citation")
        if vague or lesson.get("review_status") != "approved" or lesson.get("citation_status") != "verified":
            warnings.append(f"{label}: source/review pending qualified human verification")
        if lesson.get("review_status") == "approved" and (
            lesson.get("content_verified") is not True or lesson.get("citation_status") != "verified"
        ):
            errors.append(f"{label}: approval requires content_verified=true and verified citation")

        questions = lesson.get("questions", [])
        if not isinstance(questions, list):
            errors.append(f"{label}: questions must be a list")
        else:
            for q_index, question in enumerate(questions, 1):
                if not isinstance(question, dict) or not isinstance(question.get("question"), str) or not question["question"].strip():
                    errors.append(f"{label} question {q_index}: missing question text")
                    continue
                options, answer = question.get("options"), question.get("answerIndex")
                if options is not None and (
                    not isinstance(options, list) or len(options) < 2 or type(answer) is not int
                    or not 0 <= answer < len(options)
                ):
                    errors.append(f"{label} question {q_index}: invalid options/answerIndex")

        title_key = (norm(lesson.get("title", "")), low, high)
        if title_key in title_keys:
            errors.append(f"{label}: duplicate title for same age range")
        title_keys.add(title_key)


# Preserve the migrated activity and voice banks as build-time integrity gates.
for filename, collection, minimum in (
    ("games.json", "games", 27),
    ("noor_games.json", "lessons", 9),
    ("noor_achievements.json", "lessons", 9),
    ("lesson_phrases.json", "phrases", 3000),
):
    path = ROOT / filename
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        values = data.get(collection, [])
        if not isinstance(values, list) or len(values) < minimum:
            errors.append(f"{filename}: expected at least {minimum} {collection}, found {len(values) if isinstance(values, list) else 'invalid'}")
    except Exception as exc:
        errors.append(f"{filename}: unable to validate migrated content: {exc}")

voice_path = ROOT / "voice_phrases.json"
try:
    voice_data = json.loads(voice_path.read_text(encoding="utf-8"))
    voice_groups = voice_data.get("groups", [])
    voice_phrases = [
        phrase for group in voice_groups if isinstance(group, dict)
        for phrase in group.get("phrases", []) if isinstance(phrase, dict)
    ]
    if len(voice_groups) < 3 or len(voice_phrases) < 3700:
        errors.append(f"voice_phrases.json: incomplete voice bank ({len(voice_groups)} groups / {len(voice_phrases)} phrases)")
    if any(not isinstance(phrase.get("text"), str) or not phrase["text"].strip() for phrase in voice_phrases):
        errors.append("voice_phrases.json: empty phrase text detected")
except Exception as exc:
    errors.append(f"voice_phrases.json: unable to validate voice bank: {exc}")

# The Quran is a strict integrity gate, not an optional legacy pack.
quran_path = ROOT / "quran_surahs.json"
if not quran_path.is_file():
    errors.append("quran_surahs.json: missing complete Quran dataset")
else:
    try:
        quran = json.loads(quran_path.read_text(encoding="utf-8"))
        surahs = quran.get("surahs", [])
        if len(surahs) != 114:
            errors.append(f"quran_surahs.json: expected 114 surahs, found {len(surahs)}")
        if [s.get("surahNumber") for s in surahs] != list(range(1, 115)):
            errors.append("quran_surahs.json: surah numbers must be sequential 1..114")
        ayah_total = 0
        for surah in surahs:
            number = surah.get("surahNumber")
            ayahs = surah.get("ayahs", [])
            expected = surah.get("ayahCount")
            if not isinstance(ayahs, list) or expected != len(ayahs):
                errors.append(f"quran_surahs.json: invalid ayah count for surah {number}")
                continue
            if [a.get("number") for a in ayahs] != list(range(1, len(ayahs) + 1)):
                errors.append(f"quran_surahs.json: non-sequential ayah numbers in surah {number}")
            if any(not isinstance(a.get("text"), str) or not a["text"].strip() for a in ayahs):
                errors.append(f"quran_surahs.json: empty ayah text in surah {number}")
            ayah_total += len(ayahs)
        if ayah_total != 6236:
            errors.append(f"quran_surahs.json: expected 6,236 ayahs, found {ayah_total}")
        source = quran.get("source", {})
        if source.get("name") != "Tanzil Quran Text (Uthmani)" or not re.fullmatch(r"[0-9a-f]{64}", source.get("upstream_sha256", "")):
            errors.append("quran_surahs.json: missing Tanzil provenance or upstream SHA-256")
    except Exception as exc:
        errors.append(f"quran_surahs.json: invalid dataset: {exc}")

if errors:
    print("ERRORS:\n" + "\n".join(errors))
    print(f"Scanned {len(ALL_JSON)} JSON files; {legacy_records} legacy records; {curated_count} curated lessons.")
    raise SystemExit(1)

print(f"Validated {len(ALL_JSON)} JSON files; {legacy_records} legacy records; {len(CURATED)} curated packs / {curated_count} lessons.")
if warnings:
    print(f"REVIEW WARNINGS ({len(warnings)}):")
    for warning in warnings:
        print(f"- {warning}")
