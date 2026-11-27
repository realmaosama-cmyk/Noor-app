import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/noor_brand.dart';

class QuranLibraryScreen extends StatefulWidget {
  const QuranLibraryScreen({super.key});

  @override
  State<QuranLibraryScreen> createState() => _QuranLibraryScreenState();
}

class _QuranLibraryScreenState extends State<QuranLibraryScreen> {
  late Future<List<Map<String, dynamic>>> _surahsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _surahsFuture = _loadSurahs();
  }

  Future<List<Map<String, dynamic>>> _loadSurahs() async {
    final raw = await rootBundle.loadString(
      'assets/content/legacy/quran_surahs.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final values = (decoded['surahs'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList()
      ..sort((a, b) => (a['surahNumber'] as int)
          .compareTo(b['surahNumber'] as int));
    return values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        centerTitle: true,
      ),
      body: NoorPageBackground(
        asset: 'assets/branding/noor-bg-ocean.webp',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _surahsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('تعذر تحميل فهرس السور'));
            }
            final all = snapshot.data!;
            final filtered = all.where((surah) {
              final name = (surah['name'] as String).toLowerCase();
              final number = '${surah['surahNumber']}';
              return name.contains(_query.trim().toLowerCase()) ||
                  number.contains(_query.trim());
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن اسم السورة أو رقمها',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 19),
                      const SizedBox(width: 8),
                      Text('${all.length} سورة متاحة في مكتبة نور وفداء',
                          style: Theme.of(context).textTheme.labelLarge),
                      const Spacer(),
                      Text('${filtered.length} نتيجة',
                          style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final surah = filtered[index];
                      final number = surah['surahNumber'] as int;
                      final name = surah['name'] as String;
                      final count = (surah['ayahs'] as List).length;
                      return Material(
                        color: Theme.of(context).colorScheme.surface.withOpacity(.96),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuranSurahDetailScreen(surah: surah),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            child: Row(
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text('$number',
                                      style: const TextStyle(fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('سورة $name',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                      const SizedBox(height: 3),
                                      Text('$count آية',
                                          style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_left_rounded),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Text(
                    'نص القرآن: Tanzil Project (Uthmani). هذه النسخة الحالية تحتوي على السور المتاحة في بيانات المصدر، وليست فهرسًا كاملًا للمصحف.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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

class QuranSurahDetailScreen extends StatelessWidget {
  const QuranSurahDetailScreen({super.key, required this.surah});
  final Map<String, dynamic> surah;

  @override
  Widget build(BuildContext context) {
    final name = surah['name'] as String;
    final number = surah['surahNumber'] as int;
    final ayahs = (surah['ayahs'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('سورة $name'), centerTitle: true),
      body: NoorPageBackground(
        asset: 'assets/branding/noor-bg-ocean.webp',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text('سورة $name',
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text('السورة رقم $number • ${ayahs.length} آية'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  ayahs.map((ayah) => '${ayah['text']} ﴿${ayah['number']}﴾').join('  ۞  '),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 23, height: 2.1),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'المصدر: Tanzil Quran Text (Uthmani). يُعرض النص كما ورد في المصدر دون تعديل.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
