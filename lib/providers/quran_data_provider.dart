import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'dart:convert';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../utils/network_utils.dart';
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

  List<Surah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  QuranDataProvider() {
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
      // Using EQuran.id API for surah list
      final response = await _equranDio.get('/surat');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> surahsData = data['data'] ?? [];
        
        _surahs = surahsData.map((json) => Surah.fromEquranJson(json)).toList();
      } else {
        _error = 'Failed to load surahs';
      }
    } catch (e) {
      _error = NetworkUtils.getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAyahs(int surahNumber, {TranslationProvider? translationProvider}) async {
    if (_ayahs.containsKey(surahNumber)) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Using EQuran.id API for ayah data (Arabic and Latin text)
      final response = await _equranDio.get('/surat/$surahNumber');

      if (response.statusCode == 200) {
        final data = response.data;
        final surahData = data['data'] ?? {};
        final List<dynamic> versesData = surahData['ayat'] ?? [];
        
        final ayahs = versesData.map((json) {
          return Ayah.fromEquranJson(json, surahNumber);
        }).toList();
        _ayahs[surahNumber] = ayahs;

        // Fetch translations from current API if translation provider is available
        if (translationProvider != null) {
          await _loadTranslations(surahNumber, translationProvider);
        }
      } else {
        _error = 'Failed to load ayahs';
      }
    } catch (e) {
      _error = NetworkUtils.getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
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
    } catch (e) {
      // Translation loading failed, but don't fail the entire ayah loading
      // Translation loading failed: $e
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
