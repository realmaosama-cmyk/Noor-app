#!/usr/bin/env python3
"""Fetch the complete, verbatim Tanzil Uthmani Quran for the NOOR build.

The downloaded text is never rewritten. Only the non-ayah opening basmala
inserted by Tanzil's txt-2 export is removed from surahs 2-114 (not surah 9).
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

TEXT_URL = "https://tanzil.net/pub/download/index.php"
META_URL = "https://tanzil.net/res/text/metadata/quran-data.xml"
BASMALA = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
HEADERS = {"User-Agent": "NOOR-Quran-Builder/1.0 (+https://tanzil.net)"}


def fetch(url: str, data: bytes | None = None) -> bytes:
    request = urllib.request.Request(url, data=data, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=90) as response:
        if response.status != 200:
            raise RuntimeError(f"Download failed: {url} ({response.status})")
        return response.read()


def metadata(raw: bytes) -> list[dict]:
    root = ET.fromstring(raw)
    node = root.find("suras")
    if node is None:
        raise ValueError("Tanzil metadata has no suras element")
    result = []
    for item in node.findall("sura"):
        result.append({
            "number": int(item.attrib["index"]),
            "name": item.attrib["name"],
            "ayah_count": int(item.attrib["ayas"]),
            "revelation": item.attrib.get("type", ""),
        })
    if len(result) != 114 or sum(x["ayah_count"] for x in result) != 6236:
        raise ValueError("Tanzil metadata failed the 114/6236 integrity check")
    return result


def parse_text(raw: bytes) -> dict[int, list[dict]]:
    chapters: dict[int, list[dict]] = {}
    for line in raw.decode("utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r"^(\d+)\|(\d+)\|(.+)$", line)
        if not match:
            raise ValueError(f"Unexpected Tanzil txt-2 row: {line[:80]!r}")
        chapter, verse, text = match.groups()
        chapters.setdefault(int(chapter), []).append({
            "number": int(verse),
            "text": text,
        })
    return chapters


def strip_export_basmala(verses: list[dict], surah_number: int) -> list[dict]:
    if surah_number in (1, 9):
        return verses
    # Some txt-2 exports put the opening basmala in a separate verse-zero row.
    verses = [v for v in verses if v["number"] != 0]
    if not verses:
        return verses
    text = verses[0]["text"]
    if text.startswith(BASMALA):
        verses[0]["text"] = text[len(BASMALA):].lstrip()
    return verses


def comparison_text(value: str) -> str:
    # Ignore only vocalisation/annotation marks when checking old records against
    # the fresh publisher file; the stored Quran text itself is never normalized.
    value = value.replace("\u0640", "")
    value = re.sub(r"[\u064B-\u065F\u0670\u06D6-\u06ED\s]", "", value)
    return value


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "legacy_content/assets/content")
    root.mkdir(parents=True, exist_ok=True)
    target = root / "quran_surahs.json"
    previous = {}
    if target.exists():
        try:
            old = json.loads(target.read_text(encoding="utf-8"))
            previous = {int(s["surahNumber"]): s for s in old.get("surahs", [])}
        except Exception as exc:
            raise RuntimeError(f"Cannot read existing Quran data for cross-check: {exc}") from exc

    query = urllib.parse.urlencode({
        "quranType": "uthmani",
        "outType": "txt-2",
        "agree": "true",
    })
    raw_text = fetch(f"{TEXT_URL}?{query}")
    raw_meta = fetch(META_URL)
    chapters = parse_text(raw_text)
    chapter_meta = metadata(raw_meta)

    surahs = []
    for meta in chapter_meta:
        number = meta["number"]
        verses = strip_export_basmala(chapters.get(number, []), number)
        verses.sort(key=lambda x: x["number"])
        expected = meta["ayah_count"]
        actual_numbers = [v["number"] for v in verses]
        if actual_numbers != list(range(1, expected + 1)):
            raise ValueError(
                f"Surah {number} ({meta['name']}): expected ayahs 1..{expected}, "
                f"received {actual_numbers[:3]}...{actual_numbers[-3:]}"
            )
        if any(not v["text"].strip() for v in verses):
            raise ValueError(f"Surah {number} contains an empty ayah")

        old = previous.get(number)
        if old:
            old_ayahs = old.get("ayahs", [])
            if len(old_ayahs) != expected:
                raise ValueError(f"Existing surah {number} has an incorrect ayah count")
            for index, (before, after) in enumerate(zip(old_ayahs, verses), 1):
                if comparison_text(before["text"]) != comparison_text(after["text"]):
                    raise ValueError(
                        f"Publisher cross-check failed for {number}:{index}; "
                        "existing Quran text differs beyond optional marks"
                    )

        surahs.append({
            "id": f"surah_{number}",
            "surahNumber": number,
            "name": meta["name"],
            "ayahCount": expected,
            "ayahs": verses,
        })

    total = sum(s["ayahCount"] for s in surahs)
    if len(surahs) != 114 or total != 6236:
        raise ValueError(f"Quran integrity failure: {len(surahs)} surahs / {total} ayahs")

    digest = hashlib.sha256(raw_text).hexdigest()
    output = {
        "schema": 1,
        "source": {
            "type": "quran",
            "name": "Tanzil Quran Text (Uthmani)",
            "url": "https://tanzil.net/docs/text_license",
            "license": "CC BY 3.0 — verbatim copying only; changing the text is not allowed",
            "note": (
                "نص عثماني من مشروع تنزيل، محفوظ كما ورد في ملف txt-2. "
                "حُذفت البسملة الافتتاحية المضافة في التصدير من السور 2–114 "
                "فقط، ولا تُحذف من الفاتحة، ولا تُضاف إلى التوبة."
            ),
            "upstream_sha256": digest,
            "coverage": {"surahs": 114, "ayahs": 6236},
        },
        "surahs": surahs,
    }
    target.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    notice = {
        "source": "Tanzil Quran Text (Uthmani)",
        "url": "https://tanzil.net/download/",
        "license": "Creative Commons Attribution 3.0",
        "copyright": "Copyright (C) 2007-2021 Tanzil Project",
        "notice": (
            "Verbatim Quran text; do not modify. Include this notice and link to Tanzil "
            "when redistributing. https://tanzil.net/docs/text_license"
        ),
        "scope": "Complete Quran: 114 surahs and 6,236 ayahs.",
        "upstream_sha256": digest,
    }
    (root / "QURAN_SOURCE_NOTICE.json").write_text(
        json.dumps(notice, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"QURAN OK: {len(surahs)} surahs / {total} ayahs; Tanzil SHA-256 {digest}")


if __name__ == "__main__":
    main()
