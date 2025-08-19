import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'dart:convert';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../utils/network_utils.dart';
import '../services/local_storage_service.dart';
import '../services/toast_service.dart';
import 'translation_provider.dart';

class QuranDataProvider extends ChangeNotifier {
  static const String _equranBaseUrl = 'https://equran.id/api/v2';
  static const String _translationBaseUrl = 'https://alquran-api.pages.dev/api/quran';
  
  late final Dio _equranDio;
  late final Dio _translationDio;
  List<Surah> _surahs = [];
  final Map<int, List<Ayah>> _ayahs = {};
  final Map<int, Map<String, Map<String, String>>> _translations = {};
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  LocalStorageService? _localStorage;
  final Map<int, String?> _surahErrors = {}; // Separate errors for each surah

  List<Surah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOfflineMode => _isOfflineMode;
  
  String? getSurahError(int surahNumber) => _surahErrors[surahNumber];

  QuranDataProvider() {
    _initLocalStorage();
    _equranDio = Dio(BaseOptions(
      baseUrl: _equranBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': 'QuranNow/1.0',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    
    _translationDio = Dio(BaseOptions(
      baseUrl: _translationBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent': 'QuranNow/1.0',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    
    // Add retry interceptors
    _equranDio.interceptors.add(
      RetryInterceptor(
        dio: _equranDio,
        logPrint: print,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
    
    _translationDio.interceptors.add(
      RetryInterceptor(
        dio: _translationDio,
        logPrint: print,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
  }

  Future<void> _initLocalStorage() async {
    _localStorage = await LocalStorageService.getInstance();
  }

  List<Ayah> getAyahs(int surahNumber) {
    return _ayahs[surahNumber] ?? [];
  }

  Map<String, String> getTranslations(int surahNumber, int ayahNumber) {
    return _translations[surahNumber]?[ayahNumber.toString()] ?? {};
  }

  Future<void> loadSurahs() async {
    if (_surahs.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if we have internet connection
      final hasInternet = await NetworkUtils.hasInternetConnection();
      
      if (hasInternet) {
        // Try to load from API
        try {
          final response = await _equranDio.get('/surat');

          if (response.statusCode == 200) {
            final data = response.data;
            final List<dynamic> surahsData = data['data'] ?? [];
            
            _surahs = surahsData.map((json) => Surah.fromEquranJson(json)).toList();
            
            // Cache the data for offline use
            if (_localStorage != null) {
              await _localStorage!.cacheSurahs(surahsData.cast<Map<String, dynamic>>());
            }
            
            _isOfflineMode = false;
          } else {
            throw Exception('Failed to load surahs from API');
          }
        } catch (e) {
          // If API fails, try to load from cache
          await _loadSurahsFromCache();
        }
      } else {
        // No internet, try to load from cache
        await _loadSurahsFromCache();
      }
    } catch (e) {
      _error = NetworkUtils.getErrorMessage(e);
      ToastService.showError('Failed to load surahs: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSurahsFromCache() async {
    if (_localStorage == null) {
      await _initLocalStorage();
    }
    
    final cachedSurahs = _localStorage!.getCachedSurahs();
    if (cachedSurahs != null && cachedSurahs.isNotEmpty) {
      _surahs = cachedSurahs.map((json) => Surah.fromEquranJson(json)).toList();
      _isOfflineMode = true;
      ToastService.showOfflineMode();
    } else {
      throw Exception('No offline data available. Please connect to the internet to load the Quran data for the first time.');
    }
  }

  Future<void> loadAyahs(int surahNumber, {TranslationProvider? translationProvider}) async {
    if (_ayahs.containsKey(surahNumber)) return;

    _isLoading = true;
    _surahErrors[surahNumber] = null; // Clear any previous error for this surah
    notifyListeners();

    try {
      // Check if we have internet connection
      final hasInternet = await NetworkUtils.hasInternetConnection();
      
      if (hasInternet) {
        // Try to load from API
        try {
          final response = await _equranDio.get('/surat/$surahNumber');

          if (response.statusCode == 200) {
            final data = response.data;
            final surahData = data['data'] ?? {};
            final List<dynamic> versesData = surahData['ayat'] ?? [];
            
            final ayahs = versesData.map((json) {
              return Ayah.fromEquranJson(json, surahNumber);
            }).toList();
            _ayahs[surahNumber] = ayahs;

            // Cache the ayahs data
            if (_localStorage != null) {
              await _localStorage!.cacheAyahs(surahNumber, versesData.cast<Map<String, dynamic>>());
            }

            // Fetch translations from current API if translation provider is available
            if (translationProvider != null) {
              await _loadTranslations(surahNumber, translationProvider);
            }
            
            _isOfflineMode = false;
          } else {
            throw Exception('Failed to load ayahs from API');
          }
        } catch (e) {
          // If API fails, try to load from cache
          await _loadAyahsFromCache(surahNumber, translationProvider);
        }
      } else {
        // No internet, try to load from cache
        await _loadAyahsFromCache(surahNumber, translationProvider);
      }
    } catch (e) {
      _surahErrors[surahNumber] = NetworkUtils.getErrorMessage(e);
      ToastService.showError('Failed to load surah: ${_surahErrors[surahNumber]}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAyahsFromCache(int surahNumber, TranslationProvider? translationProvider) async {
    if (_localStorage == null) {
      await _initLocalStorage();
    }
    
    final cachedAyahs = _localStorage!.getCachedAyahs(surahNumber);
    if (cachedAyahs != null && cachedAyahs.isNotEmpty) {
      final ayahs = cachedAyahs.map((json) {
        return Ayah.fromEquranJson(json, surahNumber);
      }).toList();
      _ayahs[surahNumber] = ayahs;
      
      // Load cached translations
      final cachedTranslations = _localStorage!.getCachedTranslations(surahNumber);
      if (cachedTranslations != null) {
        _translations[surahNumber] = cachedTranslations;
      }
      
      _isOfflineMode = true;
      ToastService.showOfflineMode();
    } else {
      throw Exception('No offline data available for this surah. You need to load this surah while online to cache it for offline reading.');
    }
  }

  Future<void> _loadTranslations(int surahNumber, TranslationProvider translationProvider) async {
    try {
      final translations = await translationProvider.fetchSurahTranslations(surahNumber);
      
      if (!_translations.containsKey(surahNumber)) {
        _translations[surahNumber] = {};
      }

      for (final entry in translations.entries) {
        final lang = entry.key;
        final ayahTranslationsJson = entry.value;
        
        try {
          final ayahTranslations = json.decode(ayahTranslationsJson) as Map<String, dynamic>;
          
          for (final ayahEntry in ayahTranslations.entries) {
            final ayahNumber = ayahEntry.key;
            final translation = ayahEntry.value.toString();
            
            if (!_translations[surahNumber]!.containsKey(ayahNumber)) {
              _translations[surahNumber]![ayahNumber] = {};
            }
            _translations[surahNumber]![ayahNumber]![lang] = translation;
          }
        } catch (e) {
          // Skip invalid JSON
          continue;
        }
      }
      
      // Cache the translations
      if (_localStorage != null) {
        await _localStorage!.cacheTranslations(surahNumber, _translations[surahNumber]!);
      }
    } catch (e) {
      // Translation loading failed, but don't fail the entire ayah loading
      print('Translation loading failed: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _surahs.clear();
    _ayahs.clear();
    _translations.clear();
    _isOfflineMode = false;
    _error = null;
    _surahErrors.clear();
    notifyListeners();
  }

  void clearSurahError(int surahNumber) {
    _surahErrors.remove(surahNumber);
    notifyListeners();
  }

  void clearAllErrors() {
    _error = null;
    _surahErrors.clear();
    notifyListeners();
  }
}
