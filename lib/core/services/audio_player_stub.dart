import 'package:flutter/foundation.dart';
import 'audio_player_service.dart';

AudioPlayerService createAudioPlayerService() => StubAudioPlayerService();

class StubAudioPlayerService implements AudioPlayerService {
  @override
  bool get isPlaying => false;

  @override
  double get currentPositionSeconds => 0.0;

  @override
  double get totalDurationSeconds => 0.0;

  @override
  void pause() {}

  @override
  void play(String audioPath, {VoidCallback? onEnded}) {}

  @override
  void resume() {}

  @override
  void stop() {}
}
