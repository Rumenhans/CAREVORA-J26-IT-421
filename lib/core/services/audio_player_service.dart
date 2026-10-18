import 'package:flutter/foundation.dart';
import 'audio_player_stub.dart'
    if (dart.library.html) 'audio_player_web.dart';

abstract class AudioPlayerService {
  static final AudioPlayerService instance = createAudioPlayerService();

  void play(String audioPath, {VoidCallback? onEnded});
  void pause();
  void resume();
  void stop();
  bool get isPlaying;
  double get currentPositionSeconds;
  double get totalDurationSeconds;
}
