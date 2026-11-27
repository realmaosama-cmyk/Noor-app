from pathlib import Path
import sys

root = Path(sys.argv[1])

router_path = root / 'lib/core/router/app_router.dart'
router = router_path.read_text(encoding='utf-8')
router_import = "import '../../features/home/legacy_content_screen.dart';\n"
if router_import not in router:
    anchor = "import '../../features/home/library_screen.dart';\n"
    if anchor not in router:
        raise SystemExit('Could not find the app router library import')
    router = router.replace(anchor, anchor + router_import, 1)
route = "GoRoute(path: '/legacy-content', builder: (_, __) => const LegacyContentScreen()),"
if "path: '/legacy-content'" not in router:
    anchor = "routes: ["
    if anchor not in router:
        raise SystemExit('Could not find the app route list')
    router = router.replace(anchor, anchor + "\n      " + route, 1)
router_path.write_text(router, encoding='utf-8')

home_path = root / 'lib/features/home/home_screen.dart'
home = home_path.read_text(encoding='utf-8')
if "context.push('/legacy-content')" not in home:
    anchor = "actions: ["
    button = """
          IconButton(
              tooltip: 'مكتبة نور وفداء',
              onPressed: () => context.push('/legacy-content'),
              icon: const Icon(Icons.auto_awesome_rounded)),
"""
    if anchor not in home:
        raise SystemExit('Could not find the home app bar actions')
    home = home.replace(anchor, anchor + button, 1)
home_path.write_text(home, encoding='utf-8')

pubspec_path = root / 'pubspec.yaml'
pubspec = pubspec_path.read_text(encoding='utf-8')
for asset_dir in ('    - assets/content/legacy/\n', '    - assets/content/legacy/lessons/\n', '    - assets/content/legacy/levelcheck/\n'):
    if asset_dir not in pubspec:
        pubspec = pubspec.replace('    - assets/content/\n', '    - assets/content/\n' + asset_dir, 1)
pubspec_path.write_text(pubspec, encoding='utf-8')

branding_path = root / 'tool/configure_android_branding.sh'
branding = branding_path.read_text(encoding='utf-8')
old_paths = '''    <path android:fillColor="#FFFFFFFF" android:pathData="M54,20 L62,43 L85,54 L62,62 L54,86 L45,62 L23,54 L45,43 Z" />
    <path android:fillColor="#FFFFE091" android:pathData="M79,19 L83,29 L94,33 L83,37 L79,48 L75,37 L64,33 L75,29 Z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M25,69 L28,77 L37,80 L28,84 L25,93 L21,84 L13,80 L21,77 Z" />'''
new_paths = '''    <path android:fillColor="#FFFFFFFF" android:pathData="M54,39 C43,30 29,29 17,34 L17,75 C30,70 43,71 54,81 C65,71 78,70 91,75 L91,34 C79,29 65,30 54,39 Z" />
    <path android:fillColor="#FFB9F2E9" android:pathData="M52,41 L52,78 C42,71 31,70 21,73 L21,38 C32,34 43,35 52,41 Z" />
    <path android:fillColor="#FFFFD978" android:pathData="M54,39 L54,81 L57,81 L57,39 Z" />
    <path android:fillColor="#FFFFD978" android:pathData="M79,13 L83,25 L96,29 L83,34 L79,47 L74,34 L62,29 L74,25 Z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M28,17 C19,25 20,39 31,45 C25,35 28,24 39,18 C35,16 31,16 28,17 Z" />'''
if old_paths in branding:
    branding = branding.replace(old_paths, new_paths, 1)
branding_path.write_text(branding, encoding='utf-8')

brand_path = root / 'lib/core/widgets/noor_brand.dart'
brand = brand_path.read_text(encoding='utf-8')
start = brand.index('class _NoorMark extends StatefulWidget {')
end = brand.index('class NoorEntrance extends StatelessWidget {')
fragment = Path(__file__).with_name('noor_mark.dartfrag').read_text(encoding='utf-8')
brand = brand[:start] + fragment + '\n' + brand[end:]
brand = brand.replace('NOOR • LEARN & PLAY', 'NOOR • LEARN • GROW • SHINE')
brand_path.write_text(brand, encoding='utf-8')

logo_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 220" role="img" aria-labelledby="title desc">
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
</svg>'''
(root / 'assets/branding/noor-logo.svg').write_text(logo_svg, encoding='utf-8')
