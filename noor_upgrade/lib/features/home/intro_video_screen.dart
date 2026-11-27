import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/services/noor_sound_service.dart';
import '../../core/widgets/noor_brand.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialized;

  @override
  void initState() {
    super.initState();
    NoorSoundService.stopMusic();
    _controller = VideoPlayerController.asset(
      'assets/content/legacy/media/videos/cinematic_intro.mp4',
    );
    _initialized = _controller.initialize().then((_) async {
      await _controller.setLooping(false);
      await _controller.play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مقدمة نور وفداء')),
      body: NoorPageBackground(
        asset: 'assets/branding/noor-bg-space.webp',
        child: FutureBuilder<void>(
          future: _initialized,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('تعذر تشغيل المقدمة المرئية'));
            }
            if (snapshot.connectionState != ConnectionState.done ||
                !_controller.value.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    const SizedBox(height: 12),
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) => FilledButton.icon(
                        onPressed: () => value.isPlaying
                            ? _controller.pause()
                            : _controller.play(),
                        icon: Icon(value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                        label: Text(value.isPlaying ? 'إيقاف مؤقت' : 'تشغيل'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
