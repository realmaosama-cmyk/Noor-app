import 'dart:async';
import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

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
    final totalAyahs = values.fold<int>(
      0,
      (total, surah) => total + (surah['ayahCount'] as int),
    );
    if (values.length != 114 || totalAyahs != 6236) {
      throw StateError(
        'Quran dataset incomplete: ${values.length} surahs / $totalAyahs ayahs',
      );
    }
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
                      Text('${all.length} سورة متاحة من بيانات المصدر',
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
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
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
                    'نص عثماني كامل من مشروع تنزيل (Tanzil): 114 سورة و6,236 آية. التلاوة الصوتية تحتاج اتصالًا بالإنترنت.',
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

class QuranSurahDetailScreen extends StatefulWidget {
  const QuranSurahDetailScreen({super.key, required this.surah});
  final Map<String, dynamic> surah;

  @override
  State<QuranSurahDetailScreen> createState() => _QuranSurahDetailScreenState();
}

class _QuranSurahDetailScreenState extends State<QuranSurahDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSubscription;
  int _currentIndex = 0;
  bool _playingAll = false;
  bool _loadingAudio = false;
  String? _audioError;

  String get _name => widget.surah['name'] as String;
  int get _number => widget.surah['surahNumber'] as int;
  List<Map<String, dynamic>> get _ayahs => (widget.surah['ayahs'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _playerSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && _playingAll) {
        _playAyahAt(_currentIndex + 1);
      }
    });
  }

  Future<void> _toggleAudio() async {
    if (_loadingAudio) return;
    if (_playingAll && _player.playing) {
      await _player.pause();
      if (mounted) setState(() {});
      return;
    }
    if (_playingAll && !_player.playing) {
      unawaited(_player.play());
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _playingAll = true;
      _audioError = null;
      _currentIndex = 0;
    });
    await _playAyahAt(0);
  }

  Future<void> _playAyahAt(int index) async {
    if (!mounted || !_playingAll) return;
    if (index >= _ayahs.length) {
      setState(() {
        _playingAll = false;
        _loadingAudio = false;
        _currentIndex = 0;
      });
      await _player.stop();
      return;
    }
    final ayahNumber = _ayahs[index]['number'] as int;
    final surahCode = _number.toString().padLeft(3, '0');
    final ayahCode = ayahNumber.toString().padLeft(3, '0');
    final url = 'https://everyayah.com/data/Alafasy_128kbps/$surahCode$ayahCode.mp3';
    setState(() {
      _currentIndex = index;
      _loadingAudio = true;
      _audioError = null;
    });
    try {
      await _player.setUrl(url);
      if (!mounted || !_playingAll) return;
      setState(() => _loadingAudio = false);
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _playingAll = false;
        _loadingAudio = false;
        _audioError = 'تعذر تشغيل التلاوة. تحقق من اتصال الإنترنت ثم حاول مرة أخرى.';
      });
      await _player.stop();
    }
  }

  Future<void> _stopAudio() async {
    setState(() {
      _playingAll = false;
      _loadingAudio = false;
      _currentIndex = 0;
      _audioError = null;
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
  Widget build(BuildContext context) {
    final ayahs = _ayahs;
    final progress = ayahs.isEmpty ? 0.0 : (_currentIndex + 1) / ayahs.length;
    return Scaffold(
      appBar: AppBar(title: Text('سورة $_name'), centerTitle: true),
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
                    Text('سورة $_name',
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text('السورة رقم $_number • ${ayahs.length} آية'),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _loadingAudio ? null : _toggleAudio,
                          icon: Icon(_player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          label: Text(_loadingAudio ? 'جارٍ التحميل…' : _player.playing ? 'إيقاف مؤقت' : 'استمع للسورة كاملة'),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'إيقاف التلاوة',
                          onPressed: _stopAudio,
                          icon: const Icon(Icons.stop_rounded),
                        ),
                      ],
                    ),
                    if (_playingAll) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 5),
                      Text('الآية ${_currentIndex + 1} من ${ayahs.length}'),
                    ],
                    if (_audioError != null) ...[
                      const SizedBox(height: 8),
                      Text(_audioError!, textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      'تلاوة مشاري العفاسي • EveryAyah • يلزم اتصال بالإنترنت',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
              'نص القرآن: Tanzil Project (Uthmani). يُعرض النص كما ورد في المصدر دون تعديل.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
