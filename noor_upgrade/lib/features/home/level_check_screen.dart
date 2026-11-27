import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/noor_sound_service.dart';
import '../../core/widgets/noor_brand.dart';

class LevelCheckScreen extends StatefulWidget {
  const LevelCheckScreen({super.key, required this.age});
  final int age;

  @override
  State<LevelCheckScreen> createState() => _LevelCheckScreenState();
}

class _LevelCheckScreenState extends State<LevelCheckScreen> {
  late final Future<List<Map<String, dynamic>>> _questionsFuture = _loadQuestions();
  final Map<int, int> _answers = {};
  String _track = 'all';
  bool _submitted = false;

  String get _fileName {
    if (widget.age <= 5) return 'atfal.json';
    if (widget.age <= 8) return 'nashia.json';
    return 'murahiqun.json';
  }

  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    final raw = await rootBundle.loadString('assets/content/legacy/levelcheck/$_fileName');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final values = (decoded['questions'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    if (values.isEmpty || values.any((q) {
      final options = q['options'];
      final answer = q['answer'];
      return q['text'] is! String ||
          (q['text'] as String).trim().isEmpty ||
          options is! List ||
          options.length < 2 ||
          answer is! int ||
          answer < 0 ||
          answer >= options.length;
    })) {
      throw const FormatException('Invalid level-check question bank');
    }
    return values;
  }

  String _trackLabel(String track) => switch (track) {
        'salah' => 'الصلاة',
        'maa_la_yasa' => 'معلومات إسلامية',
        'arabic' => 'اللغة العربية',
        'quran' => 'القرآن',
        _ => 'كل المجالات',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة مهاراتي')),
      body: NoorPageBackground(
        asset: 'assets/branding/noor-bg-ocean.webp',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('تعذر تحميل أسئلة المراجعة'));
            }
            final all = snapshot.data!;
            final tracks = all
                .map((q) => (q['track'] ?? '').toString())
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final questions = all
                .asMap()
                .entries
                .where((entry) => _track == 'all' || entry.value['track'] == _track)
                .toList(growable: false);
            final answered = questions.where((entry) => _answers.containsKey(entry.key)).length;
            final correct = questions.where((entry) =>
                _answers[entry.key] == entry.value['answer']).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('اختبر ما تتذكره بهدوء',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text(
                          'هذه مراجعة تعليمية قصيرة وليست حكمًا على قدرات الطفل أو اختبارًا تشخيصيًا. يمكن لولي الأمر مراجعة الإجابات معه.',
                          textAlign: TextAlign.right,
                          style: TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _track,
                          decoration: const InputDecoration(
                            labelText: 'المجال',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('كل المجالات')),
                            for (final track in tracks)
                              DropdownMenuItem(value: track, child: Text(_trackLabel(track))),
                          ],
                          onChanged: _submitted ? null : (value) {
                            if (value != null) setState(() => _track = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: questions.isEmpty ? 0 : answered / questions.length,
                        ),
                        const SizedBox(height: 5),
                        Text('$answered من \${questions.length} سؤال تمت الإجابة عنه',
                            textAlign: TextAlign.right),
                      ],
                    ),
                  ),
                ),
                for (var i = 0; i < questions.length; i++)
                  _LevelQuestionCard(
                    key: ValueKey(questions[i].key),
                    index: i + 1,
                    question: questions[i].value,
                    selected: _answers[questions[i].key],
                    submitted: _submitted,
                    onSelect: (value) {
                      setState(() => _answers[questions[i].key] = value);
                      unawaited(NoorSoundService.playEffect('tap.wav'));
                    },
                  ),
                if (!_submitted)
                  FilledButton.icon(
                    onPressed: answered == questions.length && questions.isNotEmpty
                        ? () {
                            setState(() => _submitted = true);
                            unawaited(NoorSoundService.playEffect('success.wav'));
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('اعرض نتيجة المراجعة'),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 36),
                          const SizedBox(height: 8),
                          Text('إجابات صحيحة: $correct من \${questions.length}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          const Text(
                            'النتيجة للتشجيع ومعرفة ما يمكن مراجعته فقط؛ لا تقارنها بطفل آخر.',
                            textAlign: TextAlign.center,
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _answers.clear();
                              _submitted = false;
                            }),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('أعد المراجعة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'محتوى أسئلة المراجعة قيد المراجعة البشرية، ومصادره لا تُعد اعتمادًا شرعيًا نهائيًا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
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

class _LevelQuestionCard extends StatelessWidget {
  const _LevelQuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.selected,
    required this.submitted,
    required this.onSelect,
  });

  final int index;
  final Map<String, dynamic> question;
  final int? selected;
  final bool submitted;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = (question['options'] as List).cast<String>();
    final answer = question['answer'] as int;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('سؤال $index • \${question['text']}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800, height: 1.6)),
            for (var i = 0; i < options.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: selected,
                onChanged: submitted ? null : (value) {
                  if (value != null) onSelect(value);
                },
                title: Text(options[i], textAlign: TextAlign.right),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            if (submitted)
              Text(
                selected == answer
                    ? 'أحسنت، إجابة صحيحة'
                    : 'الإجابة الصحيحة: \${options[answer]}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: selected == answer
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if ((question['source'] ?? '').toString().isNotEmpty)
              Text('مرجع للمراجعة: \${question['source']}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
