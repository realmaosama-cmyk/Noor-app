import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Local sound effects and the original Nour & Fedaa song.
class NoorSoundService {
  NoorSoundService._();

  static final AudioPlayer _effects = AudioPlayer();
  static final AudioPlayer _music = AudioPlayer();
  static bool _enabled = true;

  static bool get enabled => _enabled;
  static bool get musicPlaying => _music.playing;

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (!value) await stopAll();
  }

  static Future<void> playEffect(String filename) async {
    if (!_enabled) return;
    const allowed = {
      'correct.wav',
      'intro_score.wav',
      'joy.wav',
      'levelup.wav',
      'success.wav',
      'tap.wav',
    };
    if (!allowed.contains(filename)) return;
    try {
      await _effects.stop();
      await _effects.setAsset(
        'assets/content/legacy/media/audio/sfx/$filename',
      );
      await _effects.play();
    } catch (_) {
      // Missing device audio output must never block a learning activity.
    }
  }

  static Future<void> playSong() async {
    if (!_enabled) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.music());
      await _music.stop();
      await _music.setLoopMode(LoopMode.off);
      await _music.setAsset(
        'assets/content/legacy/media/audio/song/nour_fedaa_song.mp3',
      );
      await _music.play();
    } catch (_) {
      // Surface a silent fallback rather than crashing the app.
    }
  }

  static Future<void> playIntroScore({bool loop = true}) async {
    if (!_enabled) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.music());
      await _music.stop();
      await _music.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _music.setAsset(
        'assets/content/legacy/media/audio/sfx/intro_score.wav',
      );
      await _music.play();
    } catch (_) {}
  }

  static Future<void> pauseMusic() => _music.pause();
  static Future<void> resumeMusic() => _music.play();
  static Future<void> stopMusic() => _music.stop();

  static Future<void> stopAll() async {
    await Future.wait([_effects.stop(), _music.stop()]);
  }
}
