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
        for key in ("lessons", "hadiths", "games", "surahs", "ayat", "verses", "challenges", "questions", "phrases"):
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
        elif collection == "phrases" and any(
            not isinstance(phrase, str) or not phrase.strip() for phrase in values
        ):
            errors.append(f"{filename}: empty or invalid phrase entry detected")
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

# The original project media must be present in the packaged asset tree.
media_root = ROOT / "media"
if not media_root.is_dir():
    errors.append("media/: missing migrated original art/audio/video assets")
else:
    art_files = list((media_root / "art").glob("*.webp"))
    sfx_files = list((media_root / "audio" / "sfx").glob("*.wav"))
    song_files = list((media_root / "audio" / "song").glob("*.mp3"))
    icon_files = list((media_root / "icons").glob("*.png"))
    video_files = list((media_root / "videos").glob("*.mp4"))
    all_media = [p for p in media_root.rglob("*") if p.is_file()]
    if len(art_files) != 161:
        errors.append(f"media/art: expected 161 illustrations, found {len(art_files)}")
    if len(sfx_files) != 6:
        errors.append(f"media/audio/sfx: expected 6 effects, found {len(sfx_files)}")
    if len(song_files) != 1:
        errors.append(f"media/audio/song: expected 1 song, found {len(song_files)}")
    if len(icon_files) != 2:
        errors.append(f"media/icons: expected 2 preserved source icons, found {len(icon_files)}")
    if len(video_files) != 1:
        errors.append(f"media/videos: expected 1 cinematic intro, found {len(video_files)}")
    if len(all_media) != 172:
        errors.append(f"media/: expected 172 migrated files, found {len(all_media)}")
    if any(path.stat().st_size <= 0 for path in all_media):
        errors.append("media/: empty or zero-byte media asset detected")

# Validate the 24-week curriculum index and every lesson reference it exposes.
content_ids = set()
for path in ALL_JSON:
    if path.name == "curriculum.json":
        continue
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        for record in records(data):
            record_id = record.get("id")
            if isinstance(record_id, str) and record_id.strip():
                content_ids.add(record_id)
    except Exception:
        pass

curriculum_path = ROOT / "curriculum.json"
try:
    curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
    weeks = curriculum.get("weeks", [])
    if len(weeks) != 24:
        errors.append(f"curriculum.json: expected 24 weeks, found {len(weeks)}")
    for week in weeks:
        week_number = week.get("week")
        days = week.get("days", [])
        if len(days) != 5:
            errors.append(f"curriculum.json: week {week_number} should contain 5 days")
        for day in days:
            lesson_ids = day.get("lessons", [])
            early_ids = day.get("earlyLessons", [])
            if not isinstance(lesson_ids, list) or not isinstance(early_ids, list):
                errors.append(f"curriculum.json: invalid lesson lists in week {week_number}, day {day.get('day')}")
                continue
            if not lesson_ids and not early_ids:
                errors.append(f"curriculum.json: no lessons linked in week {week_number}, day {day.get('day')}")
            for lesson_id in lesson_ids + early_ids:
                if lesson_id not in content_ids:
                    errors.append(f"curriculum.json: unresolved lesson id {lesson_id} in week {week_number}, day {day.get('day')}")
except Exception as exc:
    errors.append(f"curriculum.json: unable to validate 24-week index: {exc}")

# The three original level-check banks are now consumed by the in-app review screen.
for filename in ("atfal.json", "nashia.json", "murahiqun.json"):
    path = ROOT / "levelcheck" / filename
    try:
        bank = json.loads(path.read_text(encoding="utf-8"))
        questions = bank.get("questions", [])
        if len(questions) != 12:
            errors.append(f"levelcheck/{filename}: expected 12 questions, found {len(questions)}")
        if bank.get("content_verified") is not False:
            errors.append(f"levelcheck/{filename}: content_verified must remain false until human review")
        for index, question in enumerate(questions, 1):
            options = question.get("options")
            answer = question.get("answer")
            if not isinstance(question.get("text"), str) or not question["text"].strip():
                errors.append(f"levelcheck/{filename} question {index}: missing prompt")
            if (
                not isinstance(options, list)
                or len(options) < 2
                or any(not isinstance(option, str) or not option.strip() for option in options)
                or type(answer) is not int
                or not 0 <= answer < len(options)
            ):
                errors.append(f"levelcheck/{filename} question {index}: invalid options or answer index")
            if not isinstance(question.get("source"), str) or not question["source"].strip():
                errors.append(f"levelcheck/{filename} question {index}: missing source note")
    except Exception as exc:
        errors.append(f"levelcheck/{filename}: unable to validate question bank: {exc}")

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
        if (
            source.get("name") != "Tanzil Quran Text (Uthmani)"
            or source.get("upstream_sha256") != "bf4f57b968d03f4131c070b1e285da9be0e0a108a21c910e872801ca273312c8"
        ):
            errors.append("quran_surahs.json: Tanzil provenance or reviewed upstream checksum mismatch")
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
