import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentAudioUrl;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get currentAudioUrl => _currentAudioUrl;

  AudioProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onPositionChanged.listen((Duration position) {
      _position = position;
      notifyListeners();
    });
    _audioPlayer!.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      notifyListeners();
    });
    _audioPlayer!.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _isLoading = false; // We'll handle loading differently
      notifyListeners();
    });
  }

  Future<void> playAudio(String audioUrl) async {
    if (_currentAudioUrl == audioUrl && _isPlaying) {
      await pauseAudio();
      return;
    }

    if (_currentAudioUrl != audioUrl) {
      await _audioPlayer!.stop();
      _currentAudioUrl = audioUrl;
      await _audioPlayer!.play(UrlSource(audioUrl));
    } else {
      await _audioPlayer!.resume();
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer!.pause();
  }

  Future<void> stopAudio() async {
    await _audioPlayer!.stop();
    _position = Duration.zero;
    _currentAudioUrl = null;
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer!.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
