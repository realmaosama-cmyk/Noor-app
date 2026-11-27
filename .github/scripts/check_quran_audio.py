#!/usr/bin/env python3
"""Network smoke test for the exact EveryAyah URL pattern used by the app."""
import sys
import urllib.error
import urllib.request

url = "https://everyayah.com/data/Alafasy_128kbps/001001.mp3"
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
            raise RuntimeError(f"Unexpected response: HTTP {response.status}, empty={not sample}")
        if content_type and "audio" not in content_type and "octet-stream" not in content_type:
            raise RuntimeError(f"Unexpected content type: {content_type}")
        print(f"AUDIO OK: Alafasy 1:1 reachable ({response.status}, {content_type or 'unknown type'})")
except (urllib.error.URLError, TimeoutError, RuntimeError) as exc:
    print(f"AUDIO CHECK FAILED: {exc}", file=sys.stderr)
    raise SystemExit(1)
