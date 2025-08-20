import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/toast_service.dart';
import '../services/audio_cache_service.dart';

class AudioProvider extends ChangeNotifier {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentAudioUrl;
  String? _currentAyahKey; // Track which ayah is currently playing
  String _selectedQari = '01'; // Default to Abdullah Al-Juhany
  final Map<String, String> _ayahQariMap = {}; // Store Qari selection per ayah
  bool _isProcessing = false; // Prevent multiple simultaneous operations
  AudioCacheService? _audioCacheService;

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
  bool get isDownloading => _isDownloading;
  bool get isProcessing => _isProcessing;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get currentAudioUrl => _currentAudioUrl;
  String? get currentAyahKey => _currentAyahKey;
  String get selectedQari => _selectedQari;
  Map<String, String> get availableQari => _availableQari;

  AudioProvider() {
    _initAudioPlayer();
    _initAudioCacheService();
  }

  Future<void> _initAudioCacheService() async {
    _audioCacheService = await AudioCacheService.getInstance();
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

      // Check if audio is cached, if not download it
      String finalAudioUrl = audioUrl;
      if (_audioCacheService != null) {
        final isCached = await _audioCacheService!.isAudioCached(audioUrl);
        if (!isCached) {
          _isDownloading = true;
          notifyListeners();
          
          try {
            final downloadSuccess = await _audioCacheService!.downloadAndCacheAudio(audioUrl);
            if (downloadSuccess) {
              finalAudioUrl = await _audioCacheService!.getAudioUrl(audioUrl);
              ToastService.showSuccess('Audio downloaded for offline playback');
            } else {
              // Continue with online playback if download fails
              print('Download failed, using online audio');
            }
          } catch (downloadError) {
            // Handle download error and continue with online playback
            print('Download error: $downloadError');
            print('Continuing with online audio playback');
          } finally {
            // Always reset downloading state
            _isDownloading = false;
            notifyListeners();
          }
        } else {
          // Use cached audio
          finalAudioUrl = await _audioCacheService!.getAudioUrl(audioUrl);
        }
      }

      // Add a small delay to prevent rapid clicks
      await Future.delayed(const Duration(milliseconds: 100));

      // Play the new audio
      print('Playing audio: $finalAudioUrl');
      await _audioPlayer!.play(UrlSource(finalAudioUrl));
      
      // Reset processing flag after successful play
      _isProcessing = false;
    } catch (e) {
      // Handle error and reset all states
      print('Audio playback error: $e');
      _resetAudioStates();
      
      // Show toast error
      String errorMessage = 'Failed to play audio';
      if (e.toString().contains('SocketException') || e.toString().contains('Network')) {
        errorMessage = 'Network error: Please check your internet connection';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Audio file not found';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Audio loading timeout';
      }
      ToastService.showAudioError(errorMessage);
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
      ToastService.showAudioError('Failed to pause audio');
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
      ToastService.showAudioError('Failed to stop audio');
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

  // Audio cache management methods
  Future<bool> isAudioCached(String audioUrl) async {
    if (_audioCacheService != null) {
      return await _audioCacheService!.isAudioCached(audioUrl);
    }
    return false;
  }

  Future<void> downloadAudioForOffline(String audioUrl) async {
    if (_audioCacheService != null) {
      final success = await _audioCacheService!.downloadAndCacheAudio(audioUrl);
      if (success) {
        ToastService.showSuccess('Audio downloaded for offline playback');
      } else {
        ToastService.showError('Failed to download audio');
      }
    }
  }

  Future<Map<String, dynamic>> getAudioCacheStats() async {
    if (_audioCacheService != null) {
      return await _audioCacheService!.getCacheStats();
    }
    return {'totalFiles': 0, 'totalSize': 0, 'maxSize': 0, 'usagePercentage': 0};
  }

  Future<void> clearAudioCache() async {
    if (_audioCacheService != null) {
      await _audioCacheService!.clearCache();
      notifyListeners();
    }
  }

  Future<void> removeAudioFromCache(String audioUrl) async {
    if (_audioCacheService != null) {
      await _audioCacheService!.removeFromCache(audioUrl);
      notifyListeners();
    }
  }

  // Reset all audio states
  void _resetAudioStates() {
    _isLoading = false;
    _isPlaying = false;
    _isDownloading = false;
    _currentAudioUrl = null;
    _currentAyahKey = null;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
