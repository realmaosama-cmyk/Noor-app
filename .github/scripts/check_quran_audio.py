#!/usr/bin/env python3
"""Network smoke test for the EveryAyah URL pattern used by both Quran players."""
import sys
import urllib.error
import urllib.request

samples = (
    ("001001", "Al-Fatihah 1:1"),
    ("002001", "Al-Baqarah 2:1"),
    ("114006", "An-Nas 114:6"),
)
for code, label in samples:
    url = f"https://everyayah.com/data/Alafasy_128kbps/{code}.mp3"
    request = urllib.request.Request(
        url,
        headers={
            "Range": "bytes=0-1023",
            "User-Agent": "NOOR-Android-Audio-SmokeTest/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            sample = response.read(1024)
            content_type = response.headers.get("Content-Type", "").lower()
            if response.status not in (200, 206) or not sample:
                raise RuntimeError(f"HTTP {response.status}, empty={not sample}")
            if content_type and "audio" not in content_type and "octet-stream" not in content_type:
                raise RuntimeError(f"unexpected content type: {content_type}")
            print(f"AUDIO OK: {label} ({response.status}, {content_type or 'unknown type'})")
    except (urllib.error.URLError, TimeoutError, RuntimeError) as exc:
        print(f"AUDIO CHECK FAILED for {label}: {exc}", file=sys.stderr)
        raise SystemExit(1)
