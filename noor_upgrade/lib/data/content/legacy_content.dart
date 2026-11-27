import 'dart:convert';
import 'package:flutter/services.dart';

class LegacyContentItem {
  const LegacyContentItem(this.id, this.title, this.emoji, this.summary,
      this.body, this.source, this.minAge, this.maxAge);
  final String id, title, emoji, summary, body, source;
  final int minAge, maxAge;
  bool suitableFor(int age) => age >= minAge && age <= maxAge;
}

class LegacyContentRepository {
  LegacyContentRepository._();
  static final _weeks = List.generate(24, (i) => i + 1)
      .expand((w) => ['week${w}_lessons.json', 'week${w}_early_lessons.json'])
      .toList(growable: false);
  static final Map<String, List<String>> _files = {
    'quran': ['quran_lessons.json', 'section_ayat_lessons.json', 'quran_surahs.json'],
    'prayer': ['prayer_hadith.json', 'lessons/a_salah_five.json',
      'lessons/a_salah_rakat.json', ..._weeks],
    'adhkar': ['adhkar_hadith.json', 'hadith_lessons.json',
      'lessons/t_adab_after_meal.json', 'lessons/t_adab_food.json',
      'lessons/t_adab_greet.json', 'lessons/t_adab_sleep.json',
      'lessons/t_adab_sneeze.json'],
    'akhlaq': ['akhlaq_hadith.json', 'hadith_lessons.json',
      'lessons/t_akhlaq_kind_word.json', 'lessons/t_akhlaq_share.json',
      'lessons/t_akhlaq_thanks.json', 'lessons/t_akhlaq_tidy.json'],
    'seerah': ['seerah_hadith.json', 'hadith_lessons.json'],
    'figures': ['figures_hadith.json', 'hadith_lessons.json'],
    'prophets': ['prophets_lessons.json', 'prophets_ayat.json'],
    'learn': ['learn_lessons.json', 'nour_more_lessons.json', ..._weeks,
      'lessons/a_arabic_letters_1.json', 'lessons/a_arabic_letters_2.json',
      'lessons/a_arabic_letters_3.json', 'lessons/a_arabic_letters_4.json',
      'lessons/a_arabic_letters_5.json', 'lessons/a_arabic_letters_6.json',
      'lessons/a_arabic_letters_7.json'],
    'challenges': ['games.json'],
    'games': ['games.json'],
  };

  static Future<List<LegacyContentItem>> loadForSection(String sectionId, int age) async {
    final result = <String, LegacyContentItem>{};
    for (final file in _files[sectionId] ?? const <String>[]) {
      try {
        final raw = await rootBundle.loadString('assets/content/legacy/$file');
        final json = jsonDecode(raw);
        if (json is! Map<dynamic, dynamic>) continue;
        for (final key in const ['lessons', 'hadiths', 'games', 'surahs', 'ayat']) {
          final list = json[key];
          if (list is! List) continue;
          for (final rawItem in list) {
            if (rawItem is! Map<dynamic, dynamic>) continue;
            final item = _parse(Map<String, dynamic>.from(rawItem), file);
            if (item != null && item.suitableFor(age)) {
              result.putIfAbsent(item.id, () => item);
            }
          }
        }
      } catch (_) {
        // Optional legacy content must not prevent the app from opening.
      }
    }
    final items = result.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    return items.take(120).toList(growable: false);
  }

  static LegacyContentItem? _parse(Map<String, dynamic> map, String file) {
    final title = _str(map['title']);
    if (title.isEmpty) return null;
    final steps = map['steps'];
    final stepText = steps is List
        ? steps.whereType<Map<dynamic, dynamic>>().map((s) => _str(s['text'])).where((s) => s.isNotEmpty).join(' • ')
        : '';
    final body = _first([map['body'], map['kidMeaning'], map['text'], map['goal'], stepText, map['intro'], map['summary']]);
    if (body.isEmpty) return null;
    final source = map['source'];
    final sourceText = source is Map<dynamic, dynamic>
        ? _first([source['reference'], source['name']])
        : _first([source, map['book'], map['grade'], map['number'] == null ? '' : 'رقم ${map['number']}']);
    final id = _str(map['id']);
    return LegacyContentItem(
      id.isEmpty ? '$file:$title' : id,
      title,
      _str(map['emoji']).isEmpty ? '✨' : _str(map['emoji']),
      _first([map['summary'], map['kidMeaning'], map['intro'], map['goal'], body]),
      body,
      sourceText,
      _num(map['minAge'], 3),
      _num(map['maxAge'], 99),
    );
  }

  static String _str(dynamic value) => value is String ? value.trim() : '';
  static String _first(List<dynamic> values) {
    for (final value in values) {
      final text = _str(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }
  static int _num(dynamic value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}
