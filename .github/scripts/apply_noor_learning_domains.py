from pathlib import Path
import base64, re, sys, zlib
root = Path(sys.argv[1]).resolve()
def put(path, payload):
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(zlib.decompress(base64.b64decode(payload)))

put("lib/data/content/learning_domains.dart", "eNp9VMFuEzEQve9XDKdNpDS9N22RUC8RFULqMerBWTtZE8dObW+rqIoEhQKqOMIZqRwCVYWICkjlS3avfAGfwNjebJI2qhRlxzPPbzxvPObDkdIW4oRYIlS/SYm2cSuKNjc34blmhklLLFdyQ0kxhr5W2YjL/haMmDbcWEbBsMQBgEgKghmDZnvPgGTHTEOSEtlnzSgRxBh4ppTeZ0RLpNhTQ8IlnEYAiZLGrgnWTjU7yrjGJDblpslpA1Y9llvBGkgBdwIm64bYHT8bqhf8rrOsoE3NpN5Csh6XRMCB1XgScElLqgWpp1lA91GJ7YDfhQUbyggh5mo7CP4KYGptyzTpCrYaJseEC+eue3HmObrjNoUdOO0pDbXgmiuPMi5tKr2o1tbcnrRKiWymJXSWKDh1uxdHrgPvQc3lamJXLDbBPGXjGqf1uj9Bh9PDR4eObhJNoih0Tt7rnMGTbt9v6G4HN67psztqbFKiOYlLtdGRT4s3xVl+U5yDM/Of+Sy/LS7i0O95MxCIoFl+WbyFvy8vIf+F0Gn+LSy+5D+K17icheVNcYHQKvbdQYuzuGwoUv37/OnDPEElyhZ04qNMExk34pEmY6bRIDQdEG8MUkGO0DAM25mi0eP9DEfHo9UoZdaZSaY1TzKRDePDeuMhHRLOZMIeEOIWl+frhPCR9wjz9c2w2Gn+2/9feRfu/VMt8q+IOM+v53JMUagrFHlavAJHUrxzujn4ij4fr9fqI1wlrsyUCMFw5l3NBK83T9AYEuuEqUqLJcGr6AzBe2zDDLgQXiTN8LU5doFEURQGjROlBcUvkgpuHM0JE6LLQrSXlURmRDwzkXxIPBme2c+Zy68kG+OX8j7Hd855MuNPZtzz51MrNQiUmIhL7KVbuVbhdY/uN+sxiJX1E5yOWvVmhNldGjQanjv8rZkWRPu5CyCcXNjZ8STlxAZ/C2euGmKZCdHCEfwP9sc2OA==")
put("lib/features/home/learning_domain_screen.dart", "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")
put("lib/core/widgets/noor_arabic_keyboard.dart", "eNrlWFtzG7cVftevQF/C3XazuthuFMqXWrI90dSOXUuVHzweDbgLkhiDCxbAimI8mqmTOE7y3D+QmbS21XEnqZM2yS8hX/tLeg6AvXBJxnKS6Uv1AAGLg4Nz+fDhgHwwlMqQ1pAmD2mPtZM+VTQxTOnVqhunVJnW1gpvCA8ozHIqDnO+WusX4iurq6tkp89F+nZXcZalYkyuKtrhCXnIxh1JVUp4Rrp0wAWnqphbX1snitGUZz0iVcpUvJIIqjV5X0rlZH5fLGfHBvRqsmdg+24u7vG0xwx5tEJIIjNtFqwJHul8CErBhAj2+VPOFUuJ6XMdwxKjpBBMnYRboKLLMyrIPmxyPeUG7NkpBUgli5K/k0dMKZ4y6FtbLs5vfJkk4JZhdj4IyaXL5HBeys9urZyseLeXCc06v3BDjIOGWYiqC8ehkiNNLpGLN7k2F/eMAqcuX74PYoTcb03+1Ypak2+x+Ts00w+xeYzDH7D5HodPsfcPbF62HkTFwm/wwyuc/xx7z7H3MfaeYXOKw0+weYLNR7WFf8P5L7D5Epuv7UK7avoZfniBvU+x909svsPmK7f+QTPwR5IjoLgpIvyIuFTXvm2RkYVILdcxTVMMB8uYCg4V6yqm+yB4skh9ytM/DlNQ5ZAWJPKIAuyzRUgjUqROLLSZIN6cpo5KbMtK8S6pvtUMJb+6NG99oZqQRUtixQbgwiL3zhoHqx1jsSQeeii1C/boDXYvIuFXu2hbjYWQVYmhGMg8MywNiWY+izh1MrOGZ5opEzhAkyMqclYExh3iJFeKQZYWRDC24lteUDPBEsNlBqJ+UVx+26pphHOlUF85GXN9QAVYc6X2zUm1S1UGDm0sWNYz/boyOMevVYUyr1WEn2uWWynFhoIm7C7NeiywBkW4YeTj5JYvCQvoqvHfAX4KUGnb7hR56JVGtq30XmlzAqroULM0kN0u5K/tw/Ybt7d3ILQ2VNnswP2i4ZKxsPq/SiLi3dt0iayRt95ySqEfwl1lcuWtB9IhKSi1t4nzAP8vUALrK4pwdg4VS5i9XhtA0XlH2xMUrEVOYRhXVcCWV4LqSxXg5PXB0IxnzSOLjCNvVzvHcLPNen7yJiCuafdQbrX+xziumVDB15cfh1BbFFwkaIeJiDw6AGTvUCEQ21eIzPbpMCIdKQXJDZQ/ZgwWdqnQ7KSBeSmkwit7v88GLJbdAF0D48LYTu0l+N357lJArh8PaZaCrQnWXm1yB4gdkzp0/9u+FrgOtu4Cbxodg13BRnwhjIhfcstXc4EPjN2qXZp6xZsFhwp0Qbk3xsqIciB5RLefy1UXMlbOvMd7fabLWHdsbXcX6rxct8l2bRQnXCW5oCpY3wgLcW/YbvbwHgNrz7raRbrtA+51ldr2+Acs3ZbHQZ+Bcabu4PlN8OTCWhmRHUAiXGF+dIMb41aWKjFhBk05hslYJ1Swa3KUlQoQUIFHgzZjwTzGsFvXAnogYmhZ3Zz182DOxnpkJ+95a2+U/Xi0uYa2ujT5BMhsz6UgxL/Ced8JK9TWL3WP4E4ONgfb2O44uJECdj8XnXu0y65CIRwYCXmxkK+CjMBUiJZ6bJPiq7GpPt6pxsGAHr/no3ELmIX+IWdqHGuI3u2aLS695Nck3pxDVAn12eB59FaQmUWcO0IzuIMgQqENiqxjTTBubFYpqOEv6wlmn0h7CdLVAWejHzmnXSUHN/fvbgO0o/W1CNuNmlZSxVHkgwyCw7Orx1w7MN2qjeIBL5AJFNsm92cAWB7ZANjU9Nvk3GZEiiNyPgLuS6SijichH9fK4SyOSROPuRGg9cAVzNGZGGAzDGccLN51cyd3fa0hd1eOgmUOErILagJsdAxQyrQAFMDjKEfebJ6joeIDoDhkx9m9fXQ2GzsXNjZ52DIAPImmH01OJ8/J5Nnk1fQJ/IMHz7+nj/G9NE8My477u3jcK6JYf2cuTs7H7dwY8NTARWM4wBKeYJNXk5duV2sA7HrEdU7FNZZpIJs2OagP4RwPoBQzTeXw3sjuQJ0Od2J7waWbCEZVRHiCGHHhqIW8LPAOPSbSM1o/+evkBzR8+iGZfjz9dPJy8sK6Mn0yfQzunE4/h2fpL+CQe56/T494jxqpZohtKIdBuNS14peNwz4QaoGopncPGmPM9w3OgHKrEC6IamR/F7mdCfDJqBx4U/flaCdXGtHqqLThFZp8jat6VVMOY2XgLkKJq4L3/KztxgpR1tRVP/a72TA3tYPfBzbet/VUq4IWgXR8N306+ZpMn04/wVc9XBvgSOrNn8sAzu4souGSkW7KUYRlZJcf7y5OALwrtcwKYJUZmN/M0U+b3HaS1iNHQmerLn4bLlBqUZKZO0spXI8HAwalYRL0peIfoF8Czi+wanF/wOjcWVnv3YZYVyoSuKtZyRH+umZ/8QlJmXSKBUXwWlg0Cc0xWINTa7tBMQzXKG4I+4WuAnbfyhLM/+Tln+puMgwfnNHTcw2xN3VoiQsNP63djiOfAaO8AMT6Gqw4cQudaZHWPBicLqCor/A3tCV6qrfukvWOr5euX8K8c3zz0+DUvOlSmXcEi3nWxZ/UxlVRcOF8GeAb9oQ75o6RJJtFwS9Cs1BXJg+XHm5bZher/LV7Cnz0nz//hUBAT4Genk++t+l9kxs3bBzLOo3P19euvD5Z+S+jxtmI")
keyboard_file = root / "lib/core/widgets/noor_arabic_keyboard.dart"
keyboard_text = keyboard_file.read_text(encoding="utf-8").replace("import 'package:characters/characters.dart';\\n", "")
keyboard_file.write_text(keyboard_text, encoding="utf-8")

router = root / "lib/core/router/app_router.dart"
r = router.read_text(encoding="utf-8")
if "learning_domain_screen.dart" not in r:
    r = r.replace("import '../../features/home/letter_builder_game_screen.dart';",
      "import '../../features/home/letter_builder_game_screen.dart';\nimport '../../features/home/learning_domain_screen.dart';\nimport '../../features/home/quran_library_screen.dart';")
route_anchor = "path: '/section/:id'"
at = r.find(route_anchor)
route_start = r.rfind("GoRoute(", 0, at)
if at < 0 or route_start < 0: raise SystemExit("Could not locate route insertion point")
if "LearningDomainScreen(" not in r:
    r = r[:route_start] + "      GoRoute(path: '/domain/:id', builder: (_, state) => LearningDomainScreen(domainId: state.pathParameters['id']!)),\\n      " + r[route_start:]
    route_start = r.rfind("GoRoute(", 0, r.find(route_anchor))
if "QuranLibraryScreen(" not in r:
    r = r[:route_start] + "      GoRoute(path: '/quran-library', builder: (_, __) => const QuranLibraryScreen()),\\n      " + r[route_start:]
    route_start = r.rfind("GoRoute(", 0, r.find(route_anchor))
if "QuranHubScreen(" not in r:
    r = r[:route_start] + "      GoRoute(path: '/quran-hub', builder: (_, __) => const QuranHubScreen()),\\n      " + r[route_start:]
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
    color_start = h.find('  static const _colors = [')
    if color_start >= 0:
        color_end = h.find('];', color_start)
        if color_end >= 0: h = h[:color_start] + h[color_end + 2:]
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
        ]),),),);
}

"""
    h = h.replace('class _MissionCard extends StatelessWidget {', card + 'class _MissionCard extends StatelessWidget {')
home.write_text(h, encoding="utf-8")

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
