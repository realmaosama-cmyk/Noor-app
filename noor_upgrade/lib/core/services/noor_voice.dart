import 'package:flutter_tts/flutter_tts.dart';

/// Arabic text-to-speech used by the migrated phrase and lesson libraries.
/// This is device TTS, not a bundled recording; speech availability depends
/// on the Android TTS engine and installed Arabic voice data.
class NoorVoice {
  NoorVoice._();

  static final FlutterTts _engine = FlutterTts();
  static Future<void>? _initialization;
  static bool _ready = false;

  static Future<void> _initialize() async {
    if (_ready) return;
    _initialization ??= _configure();
    try {
      await _initialization;
      _ready = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  static Future<void> _configure() async {
    await _engine.setLanguage('ar');
    await _engine.setSpeechRate(0.42);
    await _engine.setPitch(1.0);
    await _engine.awaitSpeakCompletion(true);
  }

  /// Speaks [text] in Arabic. Errors are allowed to reach the UI so it can
  /// display a friendly fallback when Arabic TTS is unavailable.
  static Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    await _initialize();
    await _engine.stop();
    final result = await _engine.speak(value);
    if (result is int && result < 0) {
      throw StateError('Android text-to-speech could not start');
    }
  }

  static Future<void> stop() async {
    await _engine.stop();
  }
}
