import 'dart:convert';
import 'package:flutter/services.dart';

class LegacyContentItem {
  const LegacyContentItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.summary,
    required this.body,
    required this.source,
    required this.minAge,
    required this.maxAge,
    this.steps = const <String>[],
    this.questions = const <Map<String, dynamic>>[],
    this.week = 0,
    this.difficulty = '',
    this.category = '',
    this.contentVerified = false,
    this.reviewStatus = 'pending',
  });

  final String id, title, emoji, summary, body, source, difficulty, category, reviewStatus;
  final bool contentVerified;
  final int minAge, maxAge, week;
  final List<String> steps;
  final List<Map<String, dynamic>> questions;

  bool suitableFor(int age) => age >= minAge && age <= maxAge;
}

class LegacyContentRepository {
  LegacyContentRepository._();

  static final _weeks = List.generate(24, (i) => i + 1)
      .expand((w) => ['week${w}_lessons.json', 'week${w}_early_lessons.json'])
      .toList(growable: false);

  static final Map<String, List<String>> _files = {
    'quran': ['noor_quran.json', ..._weeks, 'quran_lessons.json', 'section_ayat_lessons.json', 'section_ayat.json', 'quran_surahs.json'],
    'prayer': ['noor_prayer.json', 'prayer_hadith.json', 'lessons/a_salah_five.json', 'lessons/a_salah_rakat.json', ..._weeks],
    'adhkar': ['noor_adhkar.json', ..._weeks, 'adhkar_hadith.json', 'hadith_lessons.json', 'lessons/t_adab_after_meal.json', 'lessons/t_adab_food.json', 'lessons/t_adab_greet.json', 'lessons/t_adab_sleep.json', 'lessons/t_adab_sneeze.json'],
    'akhlaq': ['noor_akhlaq.json', ..._weeks, 'akhlaq_hadith.json', 'hadith_lessons.json', 'lessons/t_akhlaq_kind_word.json', 'lessons/t_akhlaq_share.json', 'lessons/t_akhlaq_thanks.json', 'lessons/t_akhlaq_tidy.json'],
    'seerah': ['noor_seerah.json', ..._weeks, 'seerah_hadith.json', 'hadith_lessons.json'],
    'figures': ['noor_figures.json', ..._weeks, 'figures_hadith.json', 'hadith_lessons.json'],
    'prophets': ['noor_prophets.json', ..._weeks, 'prophets_lessons.json', 'prophets_ayat.json'],
    'learn': ['learn_lessons.json', 'nour_more_lessons.json', ..._weeks, 'lessons/a_arabic_letters_1.json', 'lessons/a_arabic_letters_2.json', 'lessons/a_arabic_letters_3.json', 'lessons/a_arabic_letters_4.json', 'lessons/a_arabic_letters_5.json', 'lessons/a_arabic_letters_6.json', 'lessons/a_arabic_letters_7.json'],
    'challenges': ['games.json'],
    'games': ['noor_games.json', 'games.json'],
    'achievements': ['noor_achievements.json'],
  };

  static const Map<String, Set<String>> _sectionCategories = {
    'quran': {'quran', 'ayat', 'surah', 'tajweed', 'memorization'},
    'prayer': {'prayer', 'salah', 'wudu', 'purification', 'طهارة', 'صلاة'},
    'adhkar': {'adhkar', 'dhikr', 'dua', 'hadith', 'أذكار', 'دعاء'},
    'akhlaq': {'akhlaq', 'manners', 'ethics', 'values', 'أخلاق', 'آداب'},
    'seerah': {'seerah', 'prophetic_biography', 'سيرة'},
    'figures': {'figures', 'companions', 'sahaba', 'scholars', 'شخصيات', 'صحابة'},
    'prophets': {'prophets', 'stories_of_prophets', 'أنبياء', 'قصص_الأنبياء'},
    'learn': {'learn', 'learning', 'education', 'arabic', 'letters', 'numbers', 'english', 'math', 'تعلم', 'تعليم'},
    'games': {'games', 'game', 'challenge', 'challenges', 'ألعاب', 'تحديات'},
    'challenges': {'games', 'game', 'challenge', 'challenges', 'ألعاب', 'تحديات'},
    'achievements': {'achievement', 'achievements', 'badge', 'badges', 'إنجازات', 'شارات'},
  };

  static final Map<String, Future<List<LegacyContentItem>>> _cache = {};

  static Future<List<LegacyContentItem>> loadForSection(String sectionId, int age) {
    final key = '$sectionId:$age';
    return _cache.putIfAbsent(key, () => _loadForSection(sectionId, age));
  }

  static Future<List<LegacyContentItem>> _loadForSection(String sectionId, int age) async {
    final files = _files[sectionId] ?? const <String>[];
    final result = <LegacyContentItem>[];
    final seenIds = <String>{};
    final seenTitles = <String>{};

    for (final file in files) {
      try {
        final raw = await rootBundle.loadString('assets/content/legacy/$file');
        for (final item in parseDocument(raw, file)) {
          if (!item.suitableFor(age) || !_belongsToSection(item, sectionId, file)) continue;
          final titleKey = _normalize(item.title);
          final duplicateKey = titleKey;
          if (seenIds.contains(item.id) || seenTitles.contains(duplicateKey)) continue;
          seenIds.add(item.id);
          seenTitles.add(duplicateKey);
          result.add(item);
        }
      } catch (error, stack) {
        // Keep optional content isolated, but expose the exact failure in debug builds.
        assert(() {
          // ignore: avoid_print
          print('NOOR content load failed [$sectionId/$file]: $error\n$stack');
          return true;
        }());
      }
    }
    // Preserve curriculum order (including week 1 -> 24) and source order.
    return List<LegacyContentItem>.unmodifiable(result);
  }

  /// Public parser entry point so regression tests exercise the production normalizer.
  static List<LegacyContentItem> parseDocument(String raw, String file) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const <LegacyContentItem>[];
    final root = Map<String, dynamic>.from(decoded);
    final candidates = <Map<String, dynamic>>[];
    for (final key in const ['lessons', 'hadiths', 'games', 'surahs', 'ayat', 'verses', 'challenges']) {
      final values = root[key];
      if (values is List) {
        for (final value in values) {
          if (value is Map) candidates.add(Map<String, dynamic>.from(value));
        }
      }
    }
    if (candidates.isEmpty && (root.containsKey('title') || root.containsKey('name'))) {
      candidates.add(root);
    }
    return List<LegacyContentItem>.unmodifiable(
      candidates.map((map) => _parse(map, file)).whereType<LegacyContentItem>(),
    );
  }

  static bool _belongsToSection(LegacyContentItem item, String section, String file) {
    if (section == 'games' || section == 'challenges' || section == 'achievements') return true;
    final category = _normalize(item.category);
    if (category.isNotEmpty) {
      final accepted = _sectionCategories[section] ?? const <String>{};
      if (accepted.contains(category)) return true;
      // General learning categories are intentionally not leaked into religious sections.
      return false;
    }
    // Legacy files without category metadata retain their explicit file assignment.
    if (file.startsWith('week')) return section == 'learn';
    if (file == 'hadith_lessons.json') return section == 'adhkar' || section == 'akhlaq' || section == 'seerah' || section == 'figures' || section == 'prayer';
    return true;
  }

  static LegacyContentItem? _parse(Map<String, dynamic> map, String file) {
    final title = _str(map['title']).isNotEmpty ? _str(map['title']) : _str(map['name']);
    if (title.isEmpty) return null;

    final steps = <String>[];
    final questions = <Map<String, dynamic>>[];

    final rawQuestions = map['questions'];
    if (rawQuestions is List) {
      for (final question in rawQuestions) {
        if (question is! Map) continue;
        final normalized = Map<String, dynamic>.from(question);
        normalized['question'] = _first([
          normalized['question'], normalized['prompt'], normalized['text'],
        ]);
        if (!normalized.containsKey('answerIndex') && normalized['answer'] is num) {
          normalized['answerIndex'] = normalized['answer'];
        }
        questions.add(normalized);
      }
    }

    final rawSteps = map['steps'];
    if (rawSteps is List) {
      for (final step in rawSteps) {
        if (step is String && step.trim().isNotEmpty) {
          steps.add(step.trim());
        } else if (step is Map) {
          final type = _str(step['type']).toLowerCase();
          if (type == 'choose' || (step['options'] is List && (step['question'] != null || step['prompt'] != null))) {
            final options = step['options'];
            final answer = step['answerIndex'] ?? step['answer'];
            if (options is List && options.length >= 2 && answer is num) {
              questions.add({
                'question': _first([step['question'], step['prompt'], step['text'], step['label']]),
                'options': options,
                'answerIndex': answer.toInt(),
                'hint': _first([step['hint'], step['feedback']]),
                'praise': _first([step['praise'], step['rewardText']]),
              });
              continue;
            }
          }
          final stepText = _first([
            step['text'], step['instruction'], step['label'], step['title'],
            step['say'], step['prompt'], step['description'],
          ]);
          if (stepText.isNotEmpty) {
            steps.add(stepText);
          } else if (type == 'reward') {
            final stars = step['stars'];
            steps.add(stars is num ? 'أكملت النشاط! نجومك: ${stars.toInt()}' : 'أكملت النشاط بنجاح!');
          } else if (type == 'listen') {
            steps.add('استمع جيدًا ثم تابع النشاط.');
          }
        }
      }
    }

    final body = _first([
      map['hadithText'], map['hadith'], map['matn'], map['verseText'], map['arabicText'], map['arabic'], map['verse'],
      map['content'], map['text'], map['body'], map['kidMeaning'],
      map['goal'], map['objective'], map['learned'], map['toddlerSay'], map['say'], map['intro'],
      if (map['ayahs'] is List)
        (map['ayahs'] as List).map((ayah) => ayah is Map ? _str(ayah['text']) : _str(ayah)).where((ayah) => ayah.isNotEmpty).join(' ۞ '),
    ]);
    final stepText = steps.join(' • ');
    final finalBody = body.isNotEmpty ? body : stepText.isNotEmpty ? stepText : _str(map['summary']);
    if (finalBody.isEmpty && questions.isEmpty) return null;

    final source = map['source'];
    final sourceParts = <String>[
      if (source is String && source.trim().isNotEmpty) source.trim(),
      if (source is Map) _first([
        source['reference'], source['name'], source['url'], source['license'],
      ]),
      _str(map['source_note']).isEmpty ? '' : _str(map['source_note']),
      _str(map['source_type']).isEmpty ? '' : 'نوع المصدر: ${map['source_type']}',
      _str(map['narrator']).isEmpty ? '' : 'الراوي: ${_str(map['narrator'])}',
      _str(map['book']).isEmpty ? '' : 'الكتاب: ${_str(map['book'])}',
      if (map['number'] is num || map['number'] is String) 'رقم: ${map['number']}',
      _str(map['grade']).isEmpty ? '' : 'الدرجة: ${_str(map['grade'])}',
      _str(map['reference']).isEmpty ? '' : _str(map['reference']),
    ].where((part) => part.trim().isNotEmpty).toList();
    final sourceText = sourceParts.toSet().join(' • ');
    final id = _str(map['id']);
    final weekMatch = RegExp(r'week(\d+)').firstMatch(file);
    return LegacyContentItem(
      id: id.isEmpty ? '$file:$title' : id,
      title: title,
      emoji: _str(map['emoji']).isEmpty ? _str(map['icon']).isEmpty ? '✨' : _str(map['icon']) : _str(map['emoji']),
      summary: _summary(map, finalBody),
      body: finalBody,
      source: sourceText,
      minAge: _ageBound(map, isMinimum: true),
      maxAge: _ageBound(map, isMinimum: false),
      steps: List<String>.unmodifiable(steps),
      questions: List<Map<String, dynamic>>.unmodifiable(questions),
      week: int.tryParse(weekMatch?.group(1) ?? '') ?? _num(map['week'], 0),
      difficulty: _str(map['difficulty']),
      category: _first([map['category'], map['section']]),
      contentVerified: map['content_verified'] == true,
      reviewStatus: _str(map['review_status']).isEmpty ? 'pending' : _str(map['review_status']),
    );
  }

  static String _summary(Map<String, dynamic> map, String body) {
    final summary = _first([
      map['summary'], map['kidMeaning'], map['intro'], map['goal'],
      map['objective'], map['learned'], map['toddlerSay'],
    ]);
    if (summary.isNotEmpty) return summary;
    return body.length > 120 ? '${body.substring(0, 117)}…' : body;
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[ًٌٍَُِّْـ]'), '')
      .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9]+'), ' ')
      .trim();

  static String _str(dynamic value) => value is String ? value.trim() : '';
  static String _first(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static int _ageBound(Map<String, dynamic> map, {required bool isMinimum}) {
    final explicit = map[isMinimum ? 'minAge' : 'maxAge'] ??
        map[isMinimum ? 'min_age' : 'max_age'];
    if (explicit is num) return explicit.toInt();
    final band = _normalize(_str(map['band']));
    if (band == 'atfal' || band == 'children' || band == 'early_childhood') {
      return isMinimum ? 3 : 8;
    }
    if (band == 'murahiq' || band == 'murahiqoon' ||
        band == 'murahiqoun' || band == 'nashia' || band == 'youth') {
      return isMinimum ? 9 : 12;
    }
    return isMinimum ? 3 : 99;
  }

  static int _num(dynamic value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}
