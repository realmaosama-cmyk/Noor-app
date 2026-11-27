from pathlib import Path
import base64, re, sys, zlib
root = Path(sys.argv[1]).resolve()
def put(path, payload):
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(zlib.decompress(base64.b64decode(payload)))

put("lib/data/content/learning_domains.dart", "eNp9VMFuEzEQve9XDKdNpDS9N22RUC8RFULqMerBWTtZE8dObW+rqIoEhQKqOMIZqRwCVYWICkjlS3avfAGfwNjebJI2qhRlxzPPbzxvPObDkdIW4oRYIlS/SYm2cSuKNjc34blmhklLLFdyQ0kxhr5W2YjL/haMmDbcWEbBsMQBgEgKghmDZnvPgGTHTEOSEtlnzSgRxBh4ppTeZ0RLpNhTQ8IlnEYAiZLGrgnWTjU7yrjGJDblpslpA1Y9llvBGkgBdwIm64bYHT8bqhf8rrOsoE3NpN5Csh6XRMCB1XgScElLqgWpp1lA91GJ7YDfhQUbyggh5mo7CP4KYGptyzTpCrYaJseEC+eue3HmObrjNoUdOO0pDbXgmiuPMi5tKr2o1tbcnrRKiWymJXSWKDh1uxdHrgPvQc3lamJXLDbBPGXjGqf1uj9Bh9PDR4eObhJNoih0Tt7rnMGTbt9v6G4HN67psztqbFKiOYlLtdGRT4s3xVl+U5yDM/Of+Sy/LS7i0O95MxCIoFl+WbyFvy8vIf+F0Gn+LSy+5D+K17icheVNcYHQKvbdQYuzuGwoUv37/OnDPEElyhZ04qNMExk34pEmY6bRIDQdEG8MUkGO0DAM25mi0eP9DEfHo9UoZdaZSaY1TzKRDePDeuMhHRLOZMIeEOIWl+frhPCR9wjz9c2w2Gn+2/9feRfu/VMt8q+IOM+v53JMUagrFHlavAJHUrxzujn4ij4fr9fqI1wlrsyUCMFw5l3NBK83T9AYEuuEqUqLJcGr6AzBe2zDDLgQXiTN8LU5doFEURQGjROlBcUvkgpuHM0JE6LLQrSXlURmRDwzkXxIPBme2c+Zy68kG+OX8j7Hd855MuNPZtzz51MrNQiUmIhL7KVbuVbhdY/uN+sxiJX1E5yOWvVmhNldGjQanjv8rZkWRPu5CyCcXNjZ8STlxAZ/C2euGmKZCdHCEfwP9sc2OA==")
put("lib/features/home/learning_domain_screen.dart", "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")
put("lib/core/widgets/noor_arabic_keyboard.dart", "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")

router = root / "lib/core/router/app_router.dart"
r = router.read_text(encoding="utf-8")
if "learning_domain_screen.dart" not in r:
    r = r.replace("import '../../features/home/letter_builder_game_screen.dart';",
      "import '../../features/home/letter_builder_game_screen.dart';\nimport '../../features/home/learning_domain_screen.dart';\nimport '../../features/home/quran_library_screen.dart';")
if "path: '/domain/:id'" not in r:
    r = r.replace("      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),",
      "      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),\n"
      "      GoRoute(path: '/domain/:id', builder: (_, state) => LearningDomainScreen(domainId: state.pathParameters['id']!)),\n"
      "      GoRoute(path: '/quran-library', builder: (_, __) => const QuranLibraryScreen()),")
router.write_text(r, encoding="utf-8")

home = root / "lib/features/home/home_screen.dart"
h = home.read_text(encoding="utf-8")
if "learning_domains.dart" not in h:
    h = h.replace("import '../../data/content/daily_content.dart';",
      "import '../../data/content/daily_content.dart';\nimport '../../data/content/learning_domains.dart';")
if "اختر طريق رحلتك" not in h:
    title_at = h.find('خريطة مغامرتك')
    if title_at < 0: title_at = h.find('GridView.builder(')
    grid_at = h.find('GridView.builder(', title_at)
    start_marker = h.rfind('NoorEntrance(', 0, title_at)
    mission_marker = h.find('delay: visible.length + 3,', grid_at)
    if title_at < 0 or grid_at < 0 or start_marker < 0 or mission_marker < 0:
        raise SystemExit("Original home-world section not found safely")
    start = h.rfind('\n', 0, start_marker) + 1
    mission_start = h.rfind('NoorEntrance(', 0, mission_marker)
    end = h.rfind('\n', 0, mission_start) + 1
    replacement = """                    NoorEntrance(delay: 1, child: Row(children: [
                      Expanded(child: Text('اختر طريق رحلتك', style: Theme.of(context).textTheme.titleLarge)),
                      Text('${visible.length} مجالًا', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800)),
                    ])),
                    const SizedBox(height: 12),
                    GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: noorLearningDomains.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, mainAxisSpacing: 12, childAspectRatio: 2.15),
                      itemBuilder: (context, index) {
                        final domain = noorLearningDomains[index];
                        final domainSections = domain.sections(visible);
                        final lessonCount = domainSections.fold<int>(0, (sum, section) => sum + lessonsForAge(section, c).length);
                        final color = domain.id == 'sharia' ? AppColors.teal : const Color(0xFF7185D8);
                        return NoorEntrance(delay: index + 2, child: _LearningDomainCard(
                          title: domain.title, subtitle: domain.subtitle, emoji: domain.emoji,
                          sectionsCount: domainSections.length, lessonsCount: lessonCount,
                          color: color, onTap: () => context.push('/domain/${domain.id}')));
                      },
                    ),
"""
    h = h[:start] + replacement + h[end:]
    h = h.replace('delay: visible.length + 3,', 'delay: 5,').replace('delay: visible.length + 4,', 'delay: 6,')
    h = re.sub(r'  static const _colors = \[.*?\n  \];\n\n', '', h, count=1, flags=re.S)
    h = re.sub(r'\nString _worldArt\(String id\) \{.*?\nclass _MissionCard', '\nclass _MissionCard', h, count=1, flags=re.S)
    card = """class _LearningDomainCard extends StatelessWidget {
  const _LearningDomainCard({required this.title, required this.subtitle, required this.emoji,
    required this.sectionsCount, required this.lessonsCount, required this.color, required this.onTap});
  final String title, subtitle, emoji;
  final int sectionsCount, lessonsCount;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.white.withValues(alpha: .96),
    borderRadius: BorderRadius.circular(25), child: InkWell(borderRadius: BorderRadius.circular(25),
      onTap: onTap, child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withValues(alpha: .20)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .07), blurRadius: 16, offset: const Offset(0,6))]),
        child: Row(children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20)), alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 34))),
          const SizedBox(width: 15),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 4), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.ink.withValues(alpha: .68))),
            const SizedBox(height: 7), Text('$sectionsCount مجال • $lessonsCount درس',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
        ]),),),),);
}

"""
    h = h.replace('class _MissionCard extends StatelessWidget {', card + 'class _MissionCard extends StatelessWidget {')
home.write_text(h, encoding="utf-8")

section = root / "lib/features/home/section_screen.dart"
s = section.read_text(encoding="utf-8")
if "package:go_router/go_router.dart" not in s:
    s = s.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:go_router/go_router.dart';")
if "ابدأ رحلتك مع القرآن" not in s:
    needle = """                    Text(section.description,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
"""
    insert = """                    Text(section.description,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (section.id == 'quran') ...[
                      Card(child: Padding(padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const Text('ابدأ رحلتك مع القرآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          const Text('اختر بين المصحف الكامل، أو الاستماع للتلاوة، أو دروس الفهم والتدبر.'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(onPressed: () => context.push('/quran-library'),
                            icon: const Icon(Icons.menu_book_rounded), label: const Text('المصحف الشريف — 114 سورة')),
                          OutlinedButton.icon(onPressed: () => context.push('/quran-recitation'),
                            icon: const Icon(Icons.headphones_rounded), label: const Text('التلاوة والاستماع')),
                          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.school_rounded),
                            title: Text('دروس قرآنية مبسطة'), subtitle: Text('تظهر دروس التعلم والاختبارات بالأسفل')),
                        ]))),
                      const SizedBox(height: 8),
                    ],
"""
    if needle not in s: raise SystemExit("Quran section insertion anchor not found")
    s = s.replace(needle, insert, 1)
section.write_text(s, encoding="utf-8")

test = root / "test/learning_domains_test.dart"
test.write_text("""import 'package:flutter_test/flutter_test.dart';
import 'package:noor/data/content/catalog.dart';
import 'package:noor/data/content/learning_domains.dart';

void main() {
  test('both domains group every existing section exactly once', () {
    final ids = noorLearningDomains.expand((domain) => domain.sectionIds).toList();
    expect(noorLearningDomains.map((domain) => domain.id).toSet(), {'sharia', 'science'});
    expect(ids.length, noorSections.length);
    expect(ids.toSet().length, ids.length);
    expect(ids.toSet(), noorSections.map((section) => section.id).toSet());
  });
}
""", encoding="utf-8")
print("NOOR learning domains, Quran navigation, and Arabic keyboard applied.")
