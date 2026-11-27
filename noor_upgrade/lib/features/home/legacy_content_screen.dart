import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/noor_brand.dart';
import '../../data/content/legacy_content.dart';
import '../../data/providers.dart';

class LegacyContentScreen extends ConsumerWidget {
  const LegacyContentScreen({super.key});

  static const _sections = <(String, String, String)>[
    ('quran', 'القرآن الكريم', '📖'),
    ('prayer', 'الصلاة والطهارة', '🕌'),
    ('adhkar', 'الأذكار والحديث', '🤲'),
    ('akhlaq', 'الأخلاق والآداب', '💚'),
    ('seerah', 'السيرة النبوية', '🌟'),
    ('figures', 'الصحابة والشخصيات', '⭐'),
    ('prophets', 'قصص الأنبياء', '🌿'),
    ('learn', 'التعلم والمناهج الأسبوعية', '🎨'),
    ('games', 'الألعاب والتحديات', '🎮'),
    ('achievements', 'الإنجازات والشارات', '🏅'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة نور')),
      body: NoorPageBackground(
        asset: 'assets/branding/noor-bg-ocean.webp',
        child: child.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('تعذر تحميل الملف')),
          data: (learner) {
            if (learner == null) {
              return const Center(child: Text('اختَر ملف المتعلم أولًا'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('رحلة معرفة أكبر',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('محتوى إضافي من مكتبة نور، مرتب حسب المرحلة العمرية لـ ${learner.name}.',
                            style: const TextStyle(height: 1.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final section in _sections)
                  FutureBuilder<List<LegacyContentItem>>(
                    future: LegacyContentRepository.loadForSection(section.$1, learner.age),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? const <LegacyContentItem>[];
                      return Card(
                        child: ExpansionTile(
                          leading: CircleAvatar(child: Text(section.$3)),
                          title: Text(section.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(snapshot.connectionState == ConnectionState.waiting
                              ? 'جارٍ تجهيز المحتوى...'
                              : '${items.length} مادة مناسبة لعمرك'),
                          children: [
                            if (snapshot.connectionState == ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.all(18),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            if (snapshot.hasError)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('تعذر تحميل هذا القسم حاليًا'),
                              ),
                            for (final item in items)
                              ExpansionTile(
                                leading: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                                title: Text(item.title),
                                subtitle: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(item.body, style: const TextStyle(fontSize: 16, height: 1.7)),
                                  ),
                                  if (item.steps.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('جرّب هذه الخطوات', style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                    const SizedBox(height: 6),
                                    for (var index = 0; index < item.steps.length; index++)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(radius: 11, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(item.steps[index], textAlign: TextAlign.right, style: const TextStyle(height: 1.5))),
                                          ],
                                        ),
                                      ),
                                  ],
                                  if (item.questions.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('فكّر وأجب', style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                    for (final question in item.questions)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${question['question'] ?? question['prompt'] ?? question['text'] ?? ''}',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(height: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                  if (item.source.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('المصدر: ${item.source}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ),
                                  ],
                                ],
                              ),
                            if (snapshot.connectionState != ConnectionState.waiting && items.isEmpty && !snapshot.hasError)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('لا توجد مواد إضافية مناسبة لهذه المرحلة.'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
