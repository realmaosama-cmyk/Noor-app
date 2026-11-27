#!/usr/bin/env python3
"""Fetch and verify the original Nour-and-fedaa media assets into NOOR."""
from __future__ import annotations

import concurrent.futures
import hashlib
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / ".github" / "legacy_media_manifest.json"
OUTPUT = ROOT / "legacy_content" / "assets" / "content" / "media"
USER_AGENT = "NOOR-Legacy-Media-Migration/1.0"


def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def download_one(item: dict) -> tuple[str, str]:
    relative = Path(item["target_path"])
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"Unsafe target path: {relative}")
    target = OUTPUT / relative
    expected_sha = item["git_blob_sha"]
    expected_size = int(item["size"])

    if target.is_file():
        existing = target.read_bytes()
        if len(existing) == expected_size and git_blob_sha(existing) == expected_sha:
            return "skipped", str(relative)

    url = (
        "https://raw.githubusercontent.com/"
        f"{json.loads(MANIFEST.read_text(encoding='utf-8'))['source_repository']}/"
        f"{json.loads(MANIFEST.read_text(encoding='utf-8'))['source_commit']}/"
        f"{item['source_path']}"
    )
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=120) as response:
        if response.status != 200:
            raise RuntimeError(f"{url}: HTTP {response.status}")
        data = response.read()

    if len(data) != expected_size:
        raise ValueError(f"{relative}: expected {expected_size} bytes, got {len(data)}")
    actual_sha = git_blob_sha(data)
    if actual_sha != expected_sha:
        raise ValueError(f"{relative}: Git blob SHA mismatch ({actual_sha})")

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    return "downloaded", str(relative)


def main() -> None:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = manifest["assets"]
    if len(assets) != 172:
        raise ValueError(f"Expected 172 pinned media files, found {len(assets)}")

    results = []
    errors = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        futures = {pool.submit(download_one, item): item for item in assets}
        for future in concurrent.futures.as_completed(futures):
            item = futures[future]
            try:
                results.append(future.result())
            except Exception as exc:
                errors.append(f"{item['target_path']}: {exc}")

    if errors:
        raise RuntimeError("Media migration failed:\n" + "\n".join(errors))

    downloaded = sum(status == "downloaded" for status, _ in results)
    skipped = sum(status == "skipped" for status, _ in results)
    total_bytes = sum(int(item["size"]) for item in assets)
    print(
        f"MEDIA OK: {len(assets)} assets / {total_bytes:,} bytes "
        f"({downloaded} downloaded, {skipped} already verified)"
    )


if __name__ == "__main__":
    main()
