// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'audio_player_service.dart';

AudioPlayerService createAudioPlayerService() => WebAudioPlayerService();

class WebAudioPlayerService implements AudioPlayerService {
  html.AudioElement? _audio;
  VoidCallback? _onEndedCallback;
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  double get currentPositionSeconds => _audio?.currentTime.toDouble() ?? 0.0;

  @override
  double get totalDurationSeconds => _audio?.duration.toDouble() ?? 0.0;

  @override
  void play(String audioPath, {VoidCallback? onEnded}) {
    stop();
    _onEndedCallback = onEnded;
    try {
      final audioUrl = audioPath.startsWith('http')
          ? audioPath
          : (audioPath.startsWith('/') ? audioPath.substring(1) : audioPath);

      _audio = html.AudioElement(audioUrl);
      _audio!.autoplay = true;
      _audio!.loop = true;
      _audio!.onEnded.listen((_) {
        _isPlaying = false;
        _onEndedCallback?.call();
      });
      _audio!.onError.listen((e) {
        debugPrint('Web audio playback error on $audioUrl: $e');
      });
      _audio!.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error starting audio playback: $e');
    }
  }

  @override
  void pause() {
    try {
      _audio?.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  @override
  void resume() {
    try {
      _audio?.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  @override
  void stop() {
    try {
      if (_audio != null) {
        _audio!.pause();
        _audio!.currentTime = 0;
        _audio = null;
      }
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }
}
