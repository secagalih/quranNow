import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _surahsKey = 'cached_surahs';
  static const String _ayahsKey = 'cached_ayahs';
  static const String _translationsKey = 'cached_translations';
  static const String _lastUpdatedKey = 'last_updated';

  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Cache surahs data
  Future<void> cacheSurahs(List<Map<String, dynamic>> surahs) async {
    try {
      final surahsJson = json.encode(surahs);
      await _prefs!.setString(_surahsKey, surahsJson);
      await _prefs!.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching surahs: $e');
    }
  }

  // Get cached surahs
  List<Map<String, dynamic>>? getCachedSurahs() {
    try {
      final surahsJson = _prefs!.getString(_surahsKey);
      if (surahsJson != null) {
        final List<dynamic> surahsList = json.decode(surahsJson);
        return surahsList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting cached surahs: $e');
    }
    return null;
  }

  // Cache ayahs data for a specific surah
  Future<void> cacheAyahs(int surahNumber, List<Map<String, dynamic>> ayahs) async {
    try {
      final ayahsJson = json.encode(ayahs);
      final key = '${_ayahsKey}_$surahNumber';
      await _prefs!.setString(key, ayahsJson);
    } catch (e) {
      print('Error caching ayahs for surah $surahNumber: $e');
    }
  }

  // Get cached ayahs for a specific surah
  List<Map<String, dynamic>>? getCachedAyahs(int surahNumber) {
    try {
      final key = '${_ayahsKey}_$surahNumber';
      final ayahsJson = _prefs!.getString(key);
      if (ayahsJson != null) {
        final List<dynamic> ayahsList = json.decode(ayahsJson);
        return ayahsList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting cached ayahs for surah $surahNumber: $e');
    }
    return null;
  }

  // Cache translations for a specific surah
  Future<void> cacheTranslations(int surahNumber, Map<String, Map<String, String>> translations) async {
    try {
      final translationsJson = json.encode(translations);
      final key = '${_translationsKey}_$surahNumber';
      await _prefs!.setString(key, translationsJson);
    } catch (e) {
      print('Error caching translations for surah $surahNumber: $e');
    }
  }

  // Get cached translations for a specific surah
  Map<String, Map<String, String>>? getCachedTranslations(int surahNumber) {
    try {
      final key = '${_translationsKey}_$surahNumber';
      final translationsJson = _prefs!.getString(key);
      if (translationsJson != null) {
        final Map<String, dynamic> translationsMap = json.decode(translationsJson);
        return translationsMap.map((key, value) => MapEntry(key, Map<String, String>.from(value)));
      }
    } catch (e) {
      print('Error getting cached translations for surah $surahNumber: $e');
    }
    return null;
  }

  // Check if data is available offline
  bool hasOfflineData() {
    return _prefs!.getString(_surahsKey) != null;
  }

  // Check if specific surah is available offline
  bool hasOfflineSurah(int surahNumber) {
    final key = '${_ayahsKey}_$surahNumber';
    return _prefs!.getString(key) != null;
  }

  // Get last update time
  DateTime? getLastUpdated() {
    try {
      final lastUpdatedString = _prefs!.getString(_lastUpdatedKey);
      if (lastUpdatedString != null) {
        return DateTime.parse(lastUpdatedString);
      }
    } catch (e) {
      print('Error getting last updated time: $e');
    }
    return null;
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      await _prefs!.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Get cache size info
  Map<String, dynamic> getCacheInfo() {
    final keys = _prefs!.getKeys();
    final surahKeys = keys.where((key) => key.startsWith(_ayahsKey)).length;
    final translationKeys = keys.where((key) => key.startsWith(_translationsKey)).length;
    
    return {
      'hasSurahs': _prefs!.getString(_surahsKey) != null,
      'cachedSurahs': surahKeys,
      'cachedTranslations': translationKeys,
      'lastUpdated': getLastUpdated(),
    };
  }
}
