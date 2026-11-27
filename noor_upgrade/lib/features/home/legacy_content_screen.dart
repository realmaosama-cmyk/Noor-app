import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/noor_brand.dart';
import '../../core/services/noor_voice.dart';
import '../../data/content/legacy_content.dart';
import '../../data/providers.dart';
import 'quran_library_screen.dart';

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
    ('games', 'ألعاب نور التعليمية', '🎮'),
    ('challenges', 'تحديات وألعاب المكتبة الأصلية', '🧩'),
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
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.volume_up_rounded)),
                    title: const Text('مكتبة الصوتيات والعبارات'),
                    subtitle: const Text('الأذكار والأحاديث وعبارات نور وفداء بصوت عربي'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const VoicePhraseLibraryScreen()),
                    ),
                  ),
                ),
                for (final section in _sections)
                  if (section.$1 == 'quran')
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Text('📖')),
                        title: Text(section.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('فهرس السور المتاحة ونصوص الآيات'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const QuranLibraryScreen()),
                        ),
                      ),
                    )
                  else
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
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Text(item.body, style: const TextStyle(fontSize: 16, height: 1.7)),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        try {
                                          await NoorVoice.speak('${item.title}. ${item.body}');
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تعذر تشغيل الصوت العربي على هذا الجهاز')),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.volume_up_rounded),
                                      label: const Text('استمع للمادة'),
                                    ),
                                  ),
                                  if (!item.contentVerified)
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: const Text(
                                        'مادة تعليمية قيد المراجعة؛ راجع ولي الأمر أو المعلم المختص مصادرها قبل اعتمادها.',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontSize: 13, height: 1.5),
                                      ),
                                    ),
                                  if (item.steps.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Align(
                                      alignment: AlignmentDirectional.centerEnd,
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
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Text('فكّر وأجب', style: TextStyle(fontWeight: FontWeight.w900)),
                                    ),
                                    for (final question in item.questions)
                                      _LegacyQuestionCard(question: question),
                                  ],
                                  if (item.source.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Text('المصدر: ${item.source}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
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


class _LegacyQuestionCard extends StatefulWidget {
  const _LegacyQuestionCard({required this.question});

  final Map<String, dynamic> question;

  @override
  State<_LegacyQuestionCard> createState() => _LegacyQuestionCardState();
}

class _LegacyQuestionCardState extends State<_LegacyQuestionCard> {
  int? _selected;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final prompt = widget.question['question'] ??
        widget.question['prompt'] ??
        widget.question['text'] ??
        '';
    final rawOptions = widget.question['options'];
    final options = rawOptions is List
        ? rawOptions.whereType<String>().toList(growable: false)
        : const <String>[];
    final answerIndex = widget.question['answerIndex'];
    final correct = answerIndex is num ? answerIndex.toInt() : -1;
    final answered = _selected != null;
    final isCorrect = _selected == correct;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$prompt', textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800, height: 1.5)),
            for (var index = 0; index < options.length; index++)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: answered ? null : () => setState(() => _selected = index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        _selected == index
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: _selected == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          options[index],
                          textAlign: TextAlign.right,
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (options.isEmpty && widget.question['answer'] is String)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => setState(() => _showAnswer = !_showAnswer),
                  child: Text(_showAnswer ? 'إخفاء الإجابة' : 'عرض الإجابة المقترحة'),
                ),
              ),
            if (_showAnswer && widget.question['answer'] is String)
              Text(
                'الإجابة المقترحة: ${widget.question['answer']}',
                textAlign: TextAlign.right,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            if (answered)
              Text(
                isCorrect
                    ? '${widget.question['praise'] ?? 'إجابة موفقة!'}'
                    : '${widget.question['hint'] ?? 'حاول مرة أخرى بعد مراجعة الدرس.'}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isCorrect ? Colors.green.shade700 : Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (answered)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => setState(() => _selected = null),
                  child: const Text('حاول مرة أخرى'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class VoicePhraseLibraryScreen extends StatefulWidget {
  const VoicePhraseLibraryScreen({super.key});

  @override
  State<VoicePhraseLibraryScreen> createState() => _VoicePhraseLibraryScreenState();
}

class _VoicePhraseLibraryScreenState extends State<VoicePhraseLibraryScreen> {
  late final Future<List<Map<String, dynamic>>> _groupsFuture = _loadGroups();
  String _selectedGroup = 'essential';
  String _query = '';

  Future<List<Map<String, dynamic>>> _loadGroups() async {
    final raw = await rootBundle.loadString('assets/content/legacy/voice_phrases.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded['groups'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الصوتيات'),
        actions: [
          IconButton(
            tooltip: 'إيقاف الصوت',
            onPressed: NoorVoice.stop,
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ],
      ),
      body: NoorPageBackground(
        asset: 'assets/branding/noor-bg-ocean.webp',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _groupsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('تعذر تحميل مكتبة الصوتيات'));
            }
            final groups = snapshot.data!;
            final selected = groups.firstWhere(
              (group) => group['id'] == _selectedGroup,
              orElse: () => groups.first,
            );
            final phrases = (selected['phrases'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .where((phrase) {
                  final text = (phrase['text'] ?? '').toString();
                  final title = (phrase['title'] ?? '').toString();
                  final source = (phrase['source'] ?? '').toString();
                  final query = _query.trim();
                  return query.isEmpty ||
                      text.contains(query) ||
                      title.contains(query) ||
                      source.contains(query);
                })
                .toList(growable: false);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: DropdownButtonFormField<String>(
                    value: selected['id'] as String,
                    decoration: const InputDecoration(
                      labelText: 'مجموعة العبارات',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final group in groups)
                        DropdownMenuItem<String>(
                          value: group['id'] as String,
                          child: Text('${group['title']} • ${(group['phrases'] as List).length}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedGroup = value);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'ابحث في العبارات والأحاديث',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('${phrases.length} عبارة'),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: phrases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final phrase = phrases[index];
                      final text = (phrase['text'] ?? '').toString();
                      final title = (phrase['title'] ?? text).toString();
                      final source = (phrase['source'] ?? phrase['narrator'] ?? '').toString();
                      return Card(
                        child: ListTile(
                          title: Text(title, textDirection: TextDirection.rtl),
                          subtitle: Text(
                            source.isEmpty || title == text ? text : '$text\n$source',
                            textDirection: TextDirection.rtl,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton.filledTonal(
                            tooltip: 'استمع',
                            onPressed: text.isEmpty ? null : () async {
                              try {
                                await NoorVoice.speak(text);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الصوت العربي غير متاح حاليًا')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.volume_up_rounded),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
