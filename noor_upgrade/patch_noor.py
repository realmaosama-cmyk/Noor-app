#!/usr/bin/env python3
"""Apply the NOOR overlay to the extracted upstream Flutter project."""
from pathlib import Path
import re
import sys

root = Path(sys.argv[1]).resolve()


def read(relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise SystemExit(f"Required NOOR source file is missing: {path}")
    return path.read_text(encoding="utf-8")


def write(relative: str, value: str) -> None:
    path = root / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


# Add the library route and its home entry exactly once.
router_path = "lib/core/router/app_router.dart"
router = read(router_path)
router_import = "import '../../features/home/legacy_content_screen.dart';\n"
if router_import not in router:
    anchor = "import '../../features/home/library_screen.dart';\n"
    if anchor not in router:
        raise SystemExit("Could not find the app router library import")
    router = router.replace(anchor, anchor + router_import, 1)

route = "GoRoute(path: '/legacy-content', builder: (_, __) => const LegacyContentScreen()),"
if "path: '/legacy-content'" not in router:
    routes_at = router.find("routes:")
    list_at = router.find("[", routes_at) if routes_at >= 0 else -1
    if list_at < 0:
        raise SystemExit("Could not find the app route list")
    router = router[:list_at + 1] + "\n      " + route + router[list_at + 1:]
write(router_path, router)

home_path = "lib/features/home/home_screen.dart"
home = read(home_path)
if "context.push('/legacy-content')" not in home:
    anchor = "actions: ["
    button = """
          IconButton(
            tooltip: 'مكتبة نور',
            onPressed: () => context.push('/legacy-content'),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
"""
    if anchor not in home:
        raise SystemExit("Could not find the home app bar actions")
    home = home.replace(anchor, anchor + button, 1)
write(home_path, home)

# Declare every migrated asset directory and every plugin used by the overlay.
pubspec = read("pubspec.yaml")
asset_dirs = (
    "assets/content/legacy/",
    "assets/content/legacy/lessons/",
    "assets/content/legacy/levelcheck/",
    "assets/content/legacy/media/art/",
    "assets/content/legacy/media/audio/sfx/",
    "assets/content/legacy/media/audio/song/",
    "assets/content/legacy/media/icons/",
    "assets/content/legacy/media/videos/",
)
for directory in asset_dirs:
    entry = f"    - {directory}\n"
    if entry not in pubspec:
        anchor = "    - assets/content/\n"
        if anchor not in pubspec:
            raise SystemExit("Could not find assets/content/ in pubspec.yaml")
        pubspec = pubspec.replace(anchor, anchor + entry, 1)

def ensure_dependency(name: str, version: str) -> None:
    global pubspec
    if re.search(rf"(?m)^  {re.escape(name)}:", pubspec):
        return
    pubspec, count = re.subn(
        r"(?m)^dependencies:[ \t]*$",
        f"dependencies:\n  {name}: {version}",
        pubspec,
        count=1,
    )
    if count != 1:
        raise SystemExit(f"Could not add {name} to pubspec dependencies")


ensure_dependency("video_player", "^2.9.1")
ensure_dependency("just_audio", "^0.9.46")
ensure_dependency("flutter_tts", "^4.2.3")
ensure_dependency("audio_session", "^0.2.4")
write("pubspec.yaml", pubspec)

# Replace the old launcher artwork only if it is still present.
branding_path = "tool/configure_android_branding.sh"
branding = read(branding_path)
old_paths = """    <path android:fillColor="#FFFFFFFF" android:pathData="M54,20 L62,43 L85,54 L62,62 L54,86 L45,62 L23,54 L45,43 Z" />
    <path android:fillColor="#FFFFE091" android:pathData="M79,19 L83,29 L94,33 L83,37 L79,48 L75,37 L64,33 L75,29 Z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M25,69 L28,77 L37,80 L28,84 L25,93 L21,84 L13,80 L21,77 Z" />"""
new_paths = """    <path android:fillColor="#FFFFFFFF" android:pathData="M54,39 C43,30 29,29 17,34 L17,75 C30,70 43,71 54,81 C65,71 78,70 91,75 L91,34 C79,29 65,30 54,39 Z" />
    <path android:fillColor="#FFB9F2E9" android:pathData="M52,41 L52,78 C42,71 31,70 21,73 L21,38 C32,34 43,35 52,41 Z" />
    <path android:fillColor="#FFFFD978" android:pathData="M54,39 L54,81 L57,81 L57,39 Z" />
    <path android:fillColor="#FFFFD978" android:pathData="M79,13 L83,25 L96,29 L83,34 L79,47 L74,34 L62,29 L74,25 Z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M28,17 C19,25 20,39 31,45 C25,35 28,24 39,18 C35,16 31,16 28,17 Z" />"""
if old_paths in branding:
    branding = branding.replace(old_paths, new_paths, 1)
write(branding_path, branding)

# The Quran recitation is streamed and Arabic TTS uses Android's installed engine.
manifest_guard = r'''
# Ensure release builds can stream EveryAyah and discover Android TTS engines.
python3 - <<'PY'
from pathlib import Path
import re

manifest_path = Path("android/app/src/main/AndroidManifest.xml")
xml = manifest_path.read_text(encoding="utf-8")
root = re.search(r"<manifest\b[^>]*>", xml)
if root is None:
    raise SystemExit("Android manifest root element not found")
insert = []
if "android.permission.INTERNET" not in xml:
    insert.append('    <uses-permission android:name="android.permission.INTERNET" />')
if "android.intent.action.TTS_SERVICE" not in xml:
    query_intent = (
        '        <intent>\n'
        '            <action android:name="android.intent.action.TTS_SERVICE" />\n'
        '        </intent>'
    )
    if "</queries>" in xml:
        xml = xml.replace("</queries>", query_intent + "\n    </queries>", 1)
    else:
        insert.append(
            '    <queries>\n' + query_intent + '\n    </queries>'
        )
if insert:
    xml = xml[:root.end()] + "\n" + "\n".join(insert) + xml[root.end():]
manifest_path.write_text(xml, encoding="utf-8")
PY
'''
if "android.intent.action.TTS_SERVICE" not in branding:
    branding += "\n" + manifest_guard
write(branding_path, branding)

# Install the animated NOOR mark into the existing brand widget.
brand_path = "lib/core/widgets/noor_brand.dart"
brand = read(brand_path)
start = brand.find("class _NoorMark extends StatefulWidget {")
end = brand.find("class NoorEntrance extends StatelessWidget {")
if start < 0 or end < 0 or end <= start:
    raise SystemExit("Could not find the NOOR mark replacement range")
fragment = (Path(__file__).with_name("noor_mark.dartfrag")).read_text(encoding="utf-8")
brand = brand[:start] + fragment + "\n" + brand[end:]
brand = brand.replace("NOOR • LEARN & PLAY", "NOOR • LEARN • GROW • SHINE")
write(brand_path, brand)

logo_svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 220" role="img" aria-labelledby="title desc">
  <title id="title">نور | NOOR</title>
  <desc id="desc">A crescent, guiding star and open book representing light and learning.</desc>
  <defs>
    <linearGradient id="a" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#0A9D91"/><stop offset="1" stop-color="#155B78"/></linearGradient>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFE5A0"/><stop offset="1" stop-color="#E8A94D"/></linearGradient>
  </defs>
  <circle cx="112" cy="110" r="94" fill="url(#a)"/>
  <path d="M75 47a29 29 0 1 0 37 43A36 36 0 0 1 75 47Z" fill="url(#g)"/>
  <path d="m151 37 10 24 26 9-26 9-10 25-9-25-25-9 25-9Z" fill="url(#g)"/>
  <path d="M112 111c-25-19-48-20-66-12v56c23-8 45-5 66 12 21-17 43-20 66-12V99c-18-8-41-7-66 12Z" fill="#fff"/>
  <path d="M112 111v56" stroke="#0D8E87" stroke-width="5" stroke-linecap="round"/>
  <text x="250" y="115" fill="#18334A" font-family="Noto Sans Arabic,Arial,sans-serif" font-size="76" font-weight="800">نور</text>
  <text x="253" y="165" fill="#0D8E87" font-family="Arial,sans-serif" font-size="27" font-weight="700" letter-spacing="7">NOOR</text>
  <text x="255" y="197" fill="#55717D" font-family="Arial,sans-serif" font-size="13" font-weight="700" letter-spacing="3">LEARN • GROW • SHINE</text>
</svg>"""
write("assets/branding/noor-logo.svg", logo_svg)

print("NOOR overlay applied: route, library, assets, audio/TTS dependencies, launcher and logo.")
