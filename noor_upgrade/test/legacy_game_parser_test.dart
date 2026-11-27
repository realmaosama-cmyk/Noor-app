import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import '../lib/data/content/legacy_content.dart';

void main() {
  test('legacy game scenarios retain their options and correct answer', () {
    final parsed = LegacyContentRepository.parseDocument(
      jsonEncode({
        'games': [
          {
            'id': 'scenario_test',
            'title': 'موقف يومي',
            'intro': 'اختاري التصرف الصحيح',
            'type': 'scenario',
            'scenarios': [
              {
                'say': 'ماذا نقول قبل الطعام؟',
                'options': [
                  {'emoji': '🤲', 'label': 'بسم الله'},
                  {'emoji': '🎈', 'label': 'هيا نلعب'},
                ],
                'answer': 0,
              },
            ],
          },
        ],
      }),
      'games.json',
    );

    expect(parsed, hasLength(1));
    expect(parsed.first.questions, hasLength(1));
    expect(parsed.first.questions.first['question'], 'ماذا نقول قبل الطعام؟');
    expect(parsed.first.questions.first['options'], ['🤲 بسم الله', '🎈 هيا نلعب']);
    expect(parsed.first.questions.first['answerIndex'], 0);
  });

  test('legacy game items and sort groups are not dropped', () {
    final parsed = LegacyContentRepository.parseDocument(
      jsonEncode({
        'games': [
          {
            'id': 'sort_test',
            'title': 'حديقة الألوان',
            'goal': 'صنفي الأشياء',
            'groups': [
              {'id': 'red', 'emoji': '🔴', 'label': 'أحمر'},
            ],
            'items': [
              {'id': 'apple', 'emoji': '🍎', 'label': 'تفاحة', 'group': 'red'},
              {'id': 'sun', 'emoji': '☀️', 'label': 'شمس', 'group': 'yellow'},
            ],
          },
        ],
      }),
      'games.json',
    );

    expect(parsed, hasLength(1));
    expect(parsed.first.steps, contains('مجموعة: 🔴 أحمر'));
    expect(parsed.first.steps, contains('🍎 تفاحة • red'));
    expect(parsed.first.steps, contains('☀️ شمس • yellow'));
  });
}
