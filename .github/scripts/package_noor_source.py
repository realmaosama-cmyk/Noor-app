#!/usr/bin/env python3
"""Create a clean, self-contained NOOR Flutter source ZIP from the CI build tree."""
from __future__ import annotations
import sys
import zipfile
from pathlib import Path

source = Path(sys.argv[1]).resolve()
destination = Path(sys.argv[2]).resolve()
if not (source / "pubspec.yaml").is_file():
    raise SystemExit("NOOR project root is missing pubspec.yaml")
if not (source / "lib").is_dir() or not (source / "assets").is_dir():
    raise SystemExit("NOOR source package must contain lib/ and assets/")

excluded_parts = {
    ".git", ".dart_tool", ".idea", ".gradle", "build", ".flutter-plugins",
    ".flutter-plugins-dependencies", ".packages", ".DS_Store", "__pycache__",
}
excluded_names = {
    "local.properties", "key.properties", "noor-release.jks", "ci-debug.keystore",
}
destination.parent.mkdir(parents=True, exist_ok=True)
if destination.exists():
    destination.unlink()

count = 0
with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=8) as archive:
    for path in sorted(source.rglob("*")):
        relative = path.relative_to(source)
        if any(part in excluded_parts for part in relative.parts):
            continue
        if path.name in excluded_names or path.is_symlink() or not path.is_file():
            continue
        archive.write(path, Path("NOOR") / relative)
        count += 1

with zipfile.ZipFile(destination, "r") as archive:
    bad = archive.testzip()
    if bad:
        raise SystemExit(f"Corrupt source ZIP entry: {bad}")
    names = set(archive.namelist())
    required = {
        "NOOR/pubspec.yaml",
        "NOOR/lib/main.dart",
        "NOOR/assets/content/legacy/quran_surahs.json",
        "NOOR/android/app/src/main/AndroidManifest.xml",
    }
    missing = sorted(required - names)
    if missing:
        raise SystemExit("Source ZIP is missing required project files: " + ", ".join(missing))
    print(f"NOOR_Source.zip verified: {count} files, {destination.stat().st_size} bytes")
