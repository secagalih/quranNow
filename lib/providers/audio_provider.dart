import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentAudioUrl;
  String? _currentAyahKey; // Track which ayah is currently playing
  String _selectedQari = '01'; // Default to Abdullah Al-Juhany
  final Map<String, String> _ayahQariMap = {}; // Store Qari selection per ayah
  bool _isProcessing = false; // Prevent multiple simultaneous operations

  // Available Qari options - using equran.id API format
  final Map<String, String> _availableQari = {
    '01': 'Abdullah-Al-Juhany',
    '02': 'Abdul-Muhsin-Al-Qasim',
    '03': 'Abdurrahman-as-Sudais',
    '04': 'Ibrahim-Al-Dossari',
    '05': 'Misyari-Rasyid-Al-Afasi',
  };

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get currentAudioUrl => _currentAudioUrl;
  String? get currentAyahKey => _currentAyahKey;
  String get selectedQari => _selectedQari;
  Map<String, String> get availableQari => _availableQari;

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
      print('Player state changed: $state');
      
      switch (state) {
        case PlayerState.playing:
          _isPlaying = true;
          _isLoading = false;
          _isProcessing = false;
          break;
        case PlayerState.paused:
          _isPlaying = false;
          _isLoading = false;
          _isProcessing = false;
          break;
        case PlayerState.stopped:
        case PlayerState.completed:
          _isPlaying = false;
          _isLoading = false;
          _isProcessing = false;
          _currentAudioUrl = null;
          _currentAyahKey = null;
          _position = Duration.zero;
          _duration = Duration.zero;
          break;
        default:
          break;
      }
      
      notifyListeners();
    });
  }

  Future<void> playAudio(String audioUrl, String ayahKey) async {
    // Prevent multiple simultaneous operations
    if (_isProcessing || _isLoading) {
      return;
    }

    _isProcessing = true;

    try {
      // If the same audio is already playing, pause it
      if (_currentAudioUrl == audioUrl && _isPlaying) {
        _isProcessing = false;
        await pauseAudio();
        return;
      }

      // If a different audio is playing, stop it first and wait for state to settle
      if (_currentAudioUrl != audioUrl && _isPlaying) {
        print('Stopping current audio to switch to new audio');
        await _audioPlayer!.stop();
        
        // Wait a bit for the stop operation to complete
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Reset all states
        _currentAudioUrl = null;
        _currentAyahKey = null;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isPlaying = false;
        _isLoading = false;
        notifyListeners();
      }

      // Set loading state and current ayah key
      _isLoading = true;
      _currentAudioUrl = audioUrl;
      _currentAyahKey = ayahKey;
      notifyListeners();

      // Add a small delay to prevent rapid clicks
      await Future.delayed(const Duration(milliseconds: 100));

      // Play the new audio
      print('Playing new audio: $audioUrl');
      await _audioPlayer!.play(UrlSource(audioUrl));
      
      // Reset processing flag after successful play
      _isProcessing = false;
    } catch (e) {
      // Handle error
      print('Audio playback error: $e');
      _isLoading = false;
      _isPlaying = false;
      _currentAudioUrl = null;
      _currentAyahKey = null;
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> pauseAudio() async {
    // Prevent multiple simultaneous operations
    if (_isProcessing || !_isPlaying) {
      return;
    }

    _isProcessing = true;

    try {
      await _audioPlayer!.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print('Pause audio error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer!.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentAudioUrl = null;
      _currentAyahKey = null;
      _isPlaying = false;
      _isLoading = false;
      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      print('Stop audio error: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer!.seek(position);
  }

  void setQari(String qariCode) {
    if (_availableQari.containsKey(qariCode)) {
      _selectedQari = qariCode;
      notifyListeners();
    }
  }

  String getQariForAyah(String ayahKey) {
    return _ayahQariMap[ayahKey] ?? '01'; // Default to Abdullah Al-Juhany
  }

  void setQariForAyah(String ayahKey, String qariCode) {
    if (_availableQari.containsKey(qariCode)) {
      // If we're changing Qari for the currently playing ayah, stop the audio
      if (_currentAyahKey == ayahKey && _isPlaying) {
        stopAudio();
      }
      _ayahQariMap[ayahKey] = qariCode;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
