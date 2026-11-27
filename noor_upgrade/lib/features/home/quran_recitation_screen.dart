import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/widgets/noor_brand.dart';

class QuranRecitationScreen extends StatefulWidget {
  const QuranRecitationScreen({super.key});

  @override
  State<QuranRecitationScreen> createState() => _QuranRecitationScreenState();
}

class _QuranRecitationScreenState extends State<QuranRecitationScreen> {
  final AudioPlayer _player = AudioPlayer();
  late final Future<List<Map<String, dynamic>>> _surahsFuture = _loadSurahs();
  StreamSubscription<PlayerState>? _playerSubscription;
  int _surahNumber = 1;
  int _ayahNumber = 1;
  bool _loading = false;
  bool _autoAdvance = true;
  String? _error;

  Future<List<Map<String, dynamic>>> _loadSurahs() async {
    final raw = await rootBundle.loadString('assets/content/legacy/quran_surahs.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final values = (decoded['surahs'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList()
      ..sort((a, b) => (a['surahNumber'] as int).compareTo(b['surahNumber'] as int));
    final total = values.fold<int>(0, (sum, item) => sum + (item['ayahCount'] as int));
    if (values.length != 114 || total != 6236) {
      throw StateError('فهرس القرآن غير مكتمل: ${values.length} سورة / $total آية');
    }
    return values;
  }

  @override
  void initState() {
    super.initState();
    _playerSubscription = _player.playerStateStream.listen((state) {
      if (mounted) setState(() {});
      if (state.processingState == ProcessingState.completed && _autoAdvance) {
        _moveAyah(1, autoplay: true);
      }
    });
  }

  Map<String, dynamic> _findSurah(List<Map<String, dynamic>> surahs) =>
      surahs.firstWhere((item) => item['surahNumber'] == _surahNumber);

  List<Map<String, dynamic>> _ayahs(Map<String, dynamic> surah) =>
      (surah['ayahs'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);

  Future<void> _play(List<Map<String, dynamic>> surahs) async {
    final surah = _findSurah(surahs);
    final ayahs = _ayahs(surah);
    if (_ayahNumber < 1 || _ayahNumber > ayahs.length) return;
    final surahCode = _surahNumber.toString().padLeft(3, '0');
    final ayahCode = _ayahNumber.toString().padLeft(3, '0');
    final url = 'https://everyayah.com/data/Alafasy_128kbps/$surahCode$ayahCode.mp3';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _player.setUrl(url);
      if (!mounted) return;
      setState(() => _loading = false);
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تشغيل التلاوة. تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
      });
    }
  }

  Future<void> _moveAyah(int delta, {bool autoplay = false, List<Map<String, dynamic>>? surahs}) async {
    final values = surahs ?? await _surahsFuture;
    var nextSurah = _surahNumber;
    var nextAyah = _ayahNumber + delta;
    final current = _findSurah(values);
    final count = current['ayahCount'] as int;
    if (nextAyah > count) {
      final index = values.indexWhere((item) => item['surahNumber'] == _surahNumber);
      if (index >= values.length - 1) {
        await _player.stop();
        return;
      }
      nextSurah = values[index + 1]['surahNumber'] as int;
      nextAyah = 1;
    } else if (nextAyah < 1) {
      final index = values.indexWhere((item) => item['surahNumber'] == _surahNumber);
      if (index <= 0) return;
      final previous = values[index - 1];
      nextSurah = previous['surahNumber'] as int;
      nextAyah = previous['ayahCount'] as int;
    }
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _surahNumber = nextSurah;
      _ayahNumber = nextAyah;
      _error = null;
    });
    if (autoplay) await _play(values);
  }

  Future<void> _selectSurah(int number) async {
    setState(() {
      _surahNumber = number;
      _ayahNumber = 1;
      _error = null;
    });
    await _player.stop();
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تلاوة القرآن الكريم')),
        body: NoorPageBackground(
          asset: 'assets/branding/noor-bg-space.webp',
          motif: '۞',
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _surahsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('تعذر تحميل فهرس القرآن الكامل'));
              }
              final surahs = snapshot.data!;
              final surah = _findSurah(surahs);
              final ayahs = _ayahs(surah);
              final current = ayahs[_ayahNumber - 1];
              final count = ayahs.length;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int>(
                        initialValue: _surahNumber,
                        decoration: const InputDecoration(
                          labelText: 'اختر السورة',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final item in surahs)
                            DropdownMenuItem<int>(
                              value: item['surahNumber'] as int,
                              child: Text('${item['surahNumber']}. ${item['name']}'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) _selectSurah(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF103C58), Color(0xFF0B8C83)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Color(0xFFFFD36C), size: 42),
                        const SizedBox(height: 10),
                        Text('سورة ${surah['name']}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text('السورة $_surahNumber من 114 • الآية $_ayahNumber من $count',
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _ayahNumber / count,
                          color: const Color(0xFFFFD36C),
                          backgroundColor: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          current['text'] as String,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 25, height: 2.0),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _loading ? null : () => _moveAyah(-1, surahs: surahs),
                              icon: const Icon(Icons.skip_previous_rounded,
                                  color: Colors.white, size: 34),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonalIcon(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      if (_player.playing) {
                                        await _player.pause();
                                        if (mounted) setState(() {});
                                      } else {
                                        await _play(surahs);
                                      }
                                    },
                              icon: Icon(_loading
                                  ? Icons.hourglass_top
                                  : _player.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded),
                              label: Text(_loading
                                  ? 'جارٍ التحميل…'
                                  : _player.playing
                                      ? 'إيقاف مؤقت'
                                      : 'استمع للآية'),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _loading ? null : () => _moveAyah(1, surahs: surahs),
                              icon: const Icon(Icons.skip_next_rounded,
                                  color: Colors.white, size: 34),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  Card(
                    child: SwitchListTile(
                      title: const Text('الانتقال للآية التالية تلقائيًا'),
                      value: _autoAdvance,
                      onChanged: (value) => setState(() => _autoAdvance = value),
                    ),
                  ),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'القارئ: مشاري العفاسي • مصدر الملفات: EveryAyah.com. '
                        'التلاوة تحتاج اتصالًا بالإنترنت؛ نص القرآن كامل ومتاح دون اتصال.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
