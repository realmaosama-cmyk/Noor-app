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
  });

  final String id, title, emoji, summary, body, source, difficulty, category;
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
    'quran': [..._weeks, 'noor_quran.json', 'quran_lessons.json', 'section_ayat_lessons.json', 'section_ayat.json', 'quran_surahs.json'],
    'prayer': ['noor_prayer.json', 'prayer_hadith.json', 'lessons/a_salah_five.json', 'lessons/a_salah_rakat.json', ..._weeks],
    'adhkar': [..._weeks, 'noor_adhkar.json', 'adhkar_hadith.json', 'hadith_lessons.json', 'lessons/t_adab_after_meal.json', 'lessons/t_adab_food.json', 'lessons/t_adab_greet.json', 'lessons/t_adab_sleep.json', 'lessons/t_adab_sneeze.json'],
    'akhlaq': [..._weeks, 'noor_akhlaq.json', 'akhlaq_hadith.json', 'hadith_lessons.json', 'lessons/t_akhlaq_kind_word.json', 'lessons/t_akhlaq_share.json', 'lessons/t_akhlaq_thanks.json', 'lessons/t_akhlaq_tidy.json'],
    'seerah': [..._weeks, 'noor_seerah.json', 'seerah_hadith.json', 'hadith_lessons.json'],
    'figures': [..._weeks, 'noor_figures.json', 'figures_hadith.json', 'hadith_lessons.json'],
    'prophets': [..._weeks, 'noor_prophets.json', 'prophets_lessons.json', 'prophets_ayat.json'],
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

  static Future<List<LegacyContentItem>> loadForSection(String sectionId, int age) async {
    final files = _files[sectionId] ?? const <String>[];
    final result = <LegacyContentItem>[];
    final seenIds = <String>{};
    final seenTitles = <String>{};

    for (final file in files) {
      try {
        final raw = await rootBundle.loadString('assets/content/legacy/$file');
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
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
        if (candidates.isEmpty && root.containsKey('title')) candidates.add(root);

        for (final map in candidates) {
          final item = _parse(map, file);
          if (item == null || !item.suitableFor(age) || !_belongsToSection(item, sectionId, file)) continue;
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

    final rawSteps = map['steps'];
    final steps = <String>[];
    if (rawSteps is List) {
      for (final step in rawSteps) {
        if (step is String && step.trim().isNotEmpty) {
          steps.add(step.trim());
        } else if (step is Map) {
          final text = _first([step['text'], step['instruction'], step['label'], step['title'], step['prompt'], step['say']]);
          if (text.isNotEmpty) steps.add(text);
        }
      }
    }

    final questions = <Map<String, dynamic>>[];
    final rawQuestions = map['questions'];
    if (rawQuestions is List) {
      for (final question in rawQuestions) {
        if (question is Map) questions.add(Map<String, dynamic>.from(question));
      }
    }

    final body = _first([
      map['hadithText'], map['hadith'], map['matn'], map['verseText'],
      map['content'], map['text'], map['body'], map['kidMeaning'],
      map['goal'], map['intro'], map['summary'],
    ]);
    final stepText = steps.join(' • ');
    final finalBody = body.isNotEmpty ? body : stepText;
    if (finalBody.isEmpty && questions.isEmpty) return null;

    final source = map['source'];
    final sourceText = source is Map
        ? _first([source['reference'], source['name'], source['book'], source['url']])
        : _first([source, map['book'], map['reference'], map['grade']]);
    final id = _str(map['id']);
    final weekMatch = RegExp(r'week(\d+)').firstMatch(file);
    return LegacyContentItem(
      id: id.isEmpty ? '$file:$title' : id,
      title: title,
      emoji: _str(map['emoji']).isEmpty ? _str(map['icon']).isEmpty ? '✨' : _str(map['icon']) : _str(map['emoji']),
      summary: _first([map['summary'], map['kidMeaning'], map['intro'], map['goal'], finalBody]),
      body: finalBody,
      source: sourceText,
      minAge: _num(map['minAge'], 3),
      maxAge: _num(map['maxAge'], 99),
      steps: List<String>.unmodifiable(steps),
      questions: List<Map<String, dynamic>>.unmodifiable(questions),
      week: int.tryParse(weekMatch?.group(1) ?? '') ?? _num(map['week'], 0),
      difficulty: _str(map['difficulty']),
      category: _str(map['category']),
    );
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

  static int _num(dynamic value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}
