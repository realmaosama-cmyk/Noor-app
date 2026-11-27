import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../lib/data/content/legacy_content.dart';

void main() {
  group('LegacyContentRepository.parseDocument', () {
    test('reads verses collections, not only ayat', () {
      final items = LegacyContentRepository.parseDocument(
        jsonEncode({
          'verses': [
            {
              'id': 'verse_001',
              'title': 'آية للتدبر',
              'text': 'أفلا يتدبرون القرآن',
              'source': 'القرآن الكريم',
              'minAge': 6,
              'maxAge': 8,
            }
          ]
        }),
        'prophets_ayat.json',
      );

      expect(items, hasLength(1));
      expect(items.single.body, 'أفلا يتدبرون القرآن');
    });

    test('keeps string steps and includes them when body is absent', () {
      final items = LegacyContentRepository.parseDocument(
        jsonEncode({
          'lessons': [
            {
              'id': 'steps_strings',
              'title': 'خطوات النشاط',
              'summary': 'تجربة قصيرة',
              'steps': ['لاحظ الصورة', 'اختر الإجابة', 'راجع اختيارك'],
              'source': 'نشاط تعليمي',
            }
          ]
        }),
        'noor_games.json',
      );

      expect(items, hasLength(1));
      expect(items.single.steps, ['لاحظ الصورة', 'اختر الإجابة', 'راجع اختيارك']);
      expect(items.single.body, contains('لاحظ الصورة'));
    });

    test('normalizes structured steps and reflection questions', () {
      final items = LegacyContentRepository.parseDocument(
        jsonEncode({
          'lessons': [
            {
              'id': 'steps_maps',
              'title': 'نشاط منظم',
              'body': 'نص الدرس',
              'steps': [
                {'type': 'listen', 'text': 'استمع جيدًا'},
                {'type': 'choose', 'label': 'اختر الصورة'},
                {'type': 'reward', 'instruction': 'أحسنت، راجع إجابتك'}
              ],
              'questions': [
                {'question': 'ما الذي تعلمته؟', 'answer': 'التعاون'}
              ],
              'source': 'نشاط تعليمي',
            }
          ]
        }),
        'lesson.json',
      );

      expect(items, hasLength(1));
      expect(items.single.steps, ['استمع جيدًا', 'اختر الصورة', 'أحسنت، راجع إجابتك']);
      expect(items.single.questions, hasLength(1));
    });

    test('prefers complete hadith text over child explanation', () {
      final items = LegacyContentRepository.parseDocument(
        jsonEncode({
          'hadiths': [
            {
              'id': 'hadith_001',
              'title': 'حديث للتعلم',
              'hadithText': 'النص الكامل للحديث',
              'kidMeaning': 'شرح مبسط للطفل',
              'narrator': 'الراوي',
              'book': 'صحيح البخاري',
              'number': 8,
              'grade': 'صحيح',
            }
          ]
        }),
        'prayer_hadith.json',
      );

      expect(items.single.body, 'النص الكامل للحديث');
      expect(items.single.source, contains('الراوي'));
      expect(items.single.source, contains('صحيح البخاري'));
      expect(items.single.source, contains('رقم: 8'));
      expect(items.single.source, contains('صحيح'));
    });
  });
}
