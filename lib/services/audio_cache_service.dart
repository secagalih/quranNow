import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/toast_service.dart';

class AudioCacheService {
  static const String _cacheInfoKey = 'audio_cache_info';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB max cache size
  
  static AudioCacheService? _instance;
  static Directory? _cacheDirectory;
  static final Dio _dio = Dio();

  AudioCacheService._();

  static Future<AudioCacheService> getInstance() async {
    if (_instance == null) {
      _instance = AudioCacheService._();
      await _initCacheDirectory();
    }
    return _instance!;
  }

  static Future<void> _initCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/audio_cache');
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
  }

  // Get cached audio file path
  String _getAudioFilePath(String audioUrl) {
    final fileName = audioUrl.split('/').last;
    return '${_cacheDirectory!.path}/$fileName';
  }

  // Check if audio is cached
  Future<bool> isAudioCached(String audioUrl) async {
    final filePath = _getAudioFilePath(audioUrl);
    final file = File(filePath);
    return await file.exists();
  }

  // Get cached audio file
  File? getCachedAudioFile(String audioUrl) {
    final filePath = _getAudioFilePath(audioUrl);
    final file = File(filePath);
    return file.existsSync() ? file : null;
  }

  // Download and cache audio file
  Future<bool> downloadAndCacheAudio(String audioUrl) async {
    try {
      final filePath = _getAudioFilePath(audioUrl);
      final file = File(filePath);

      // Check if already cached
      if (await file.exists()) {
        return true;
      }

      // Check cache size before downloading
      await _manageCacheSize();

      // Download the file with timeout
      final response = await _dio.download(
        audioUrl,
        filePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          // You can add progress callback here if needed
        },
      );

      if (response.statusCode == 200) {
        // Update cache info
        await _updateCacheInfo(audioUrl, file.lengthSync());
        return true;
      }

      // If download failed, clean up partial file
      if (await file.exists()) {
        await file.delete();
      }
      return false;
    } catch (e) {
      print('Error downloading audio: $e');
      
      // Clean up partial file if it exists
      try {
        final filePath = _getAudioFilePath(audioUrl);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (cleanupError) {
        print('Error cleaning up partial download: $cleanupError');
      }
      
      ToastService.showError('Failed to download audio');
      return false;
    }
  }

  // Get audio URL for playback (cached or remote)
  Future<String> getAudioUrl(String audioUrl) async {
    if (await isAudioCached(audioUrl)) {
      final file = getCachedAudioFile(audioUrl);
      return file!.path;
    }
    return audioUrl;
  }

  // Update cache information
  Future<void> _updateCacheInfo(String audioUrl, int fileSize) async {
    try {
      final cacheInfo = await _getCacheInfo();
      cacheInfo['files'][audioUrl] = {
        'size': fileSize,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      cacheInfo['totalSize'] = (cacheInfo['totalSize'] ?? 0) + fileSize;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheInfoKey, json.encode(cacheInfo));
    } catch (e) {
      print('Error updating cache info: $e');
    }
  }

  // Get cache information
  Future<Map<String, dynamic>> _getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheInfoString = prefs.getString(_cacheInfoKey);
      if (cacheInfoString != null) {
        return Map<String, dynamic>.from(json.decode(cacheInfoString));
      }
    } catch (e) {
      print('Error getting cache info: $e');
    }
    return {'files': {}, 'totalSize': 0};
  }

  // Manage cache size by removing oldest files if needed
  Future<void> _manageCacheSize() async {
    try {
      final cacheInfo = await _getCacheInfo();
      int totalSize = cacheInfo['totalSize'] ?? 0;

      if (totalSize > _maxCacheSize) {
        // Sort files by timestamp (oldest first)
        final files = Map<String, dynamic>.from(cacheInfo['files'] ?? {});
        final sortedFiles = files.entries.toList()
          ..sort((a, b) => (a.value['timestamp'] ?? 0).compareTo(b.value['timestamp'] ?? 0));

        // Remove oldest files until we're under the limit
        for (final entry in sortedFiles) {
          if (totalSize <= _maxCacheSize) break;

          final audioUrl = entry.key;
          final fileSize = (entry.value['size'] ?? 0) as int;
          
          // Remove file
          final filePath = _getAudioFilePath(audioUrl);
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }

          // Update cache info
          files.remove(audioUrl);
          totalSize -= fileSize;
        }

        // Save updated cache info
        cacheInfo['files'] = files;
        cacheInfo['totalSize'] = totalSize;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheInfoKey, json.encode(cacheInfo));
      }
    } catch (e) {
      print('Error managing cache size: $e');
    }
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheInfo = await _getCacheInfo();
      final files = Map<String, dynamic>.from(cacheInfo['files'] ?? {});
      
      return {
        'totalFiles': files.length,
        'totalSize': cacheInfo['totalSize'] ?? 0,
        'maxSize': _maxCacheSize,
        'usagePercentage': ((cacheInfo['totalSize'] ?? 0) / _maxCacheSize * 100).round().toInt(),
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {'totalFiles': 0, 'totalSize': 0, 'maxSize': _maxCacheSize, 'usagePercentage': 0};
    }
  }

  // Clear all cached audio files
  Future<void> clearCache() async {
    try {
      if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create();
      }
      
      // Clear cache info
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheInfoKey);
      
      ToastService.showSuccess('Audio cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
      ToastService.showError('Failed to clear cache');
    }
  }

  // Remove specific audio file from cache
  Future<void> removeFromCache(String audioUrl) async {
    try {
      final filePath = _getAudioFilePath(audioUrl);
      final file = File(filePath);
      
      if (await file.exists()) {
        final fileSize = await file.length();
        await file.delete();
        
        // Update cache info
        final cacheInfo = await _getCacheInfo();
        final files = Map<String, dynamic>.from(cacheInfo['files'] ?? {});
        files.remove(audioUrl);
        cacheInfo['files'] = files;
        cacheInfo['totalSize'] = (cacheInfo['totalSize'] ?? 0) - fileSize;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheInfoKey, json.encode(cacheInfo));
      }
    } catch (e) {
      print('Error removing from cache: $e');
    }
  }
}
