import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationProvider extends ChangeNotifier {
  static const String _selectedLanguageKey = 'selected_language';
  static const String _baseUrl = 'https://alquran-api.pages.dev/api/quran';
  
  final Map<String, String> _availableLanguages = {
    'en': 'English',
    'ar': 'العربية',
    'bn': 'বাংলা',
    'es': 'Español',
    'fr': 'Français',
    'id': 'Bahasa Indonesia',
    'ru': 'Русский',
    'sv': 'Svenska',
    'tr': 'Türkçe',
    'ur': 'اردو',
    'zh': '中文',
    'transliteration': 'Transliteration',
  };

  final Map<String, String> _languageNames = {
    'en': 'English',
    'ar': 'Arabic',
    'bn': 'Bengali',
    'es': 'Spanish',
    'fr': 'French',
    'id': 'Indonesian',
    'ru': 'Russian',
    'sv': 'Swedish',
    'tr': 'Turkish',
    'ur': 'Urdu',
    'zh': 'Chinese',
    'transliteration': 'Transliteration',
  };

  final Map<String, String> _languageDirections = {
    'en': 'ltr',
    'ar': 'rtl',
    'bn': 'ltr',
    'es': 'ltr',
    'fr': 'ltr',
    'id': 'ltr',
    'ru': 'ltr',
    'sv': 'ltr',
    'tr': 'ltr',
    'ur': 'rtl',
    'zh': 'ltr',
    'transliteration': 'ltr',
  };

  String _selectedLanguage = 'en';
  bool _isLoading = false;
  String? _error;

  String get selectedLanguage => _selectedLanguage;
  Map<String, String> get availableLanguages => _availableLanguages;
  Map<String, String> get languageNames => _languageNames;
  Map<String, String> get languageDirections => _languageDirections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TranslationProvider() {
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString(_selectedLanguageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_availableLanguages.containsKey(languageCode)) return;
    
    _selectedLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, languageCode);
    notifyListeners();
  }

  Future<Map<String, String>> fetchTranslations(int surahNumber, int ayahNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final Map<String, String> translations = {};
    
    try {
      // Fetch translations for all available languages
      for (final lang in _availableLanguages.keys) {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/surah/$surahNumber/$lang'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final verses = data['verses'] as List<dynamic>?;
            if (verses != null) {
              final ayah = verses.firstWhere(
                (v) => v['id'] == ayahNumber,
                orElse: () => null,
              );
              if (ayah != null) {
                final translation = ayah['translation'] ?? '';
                if (translation.isNotEmpty) {
                  translations[lang] = translation;
                }
              }
            }
          }
        } catch (e) {
          // Continue with other languages if one fails
          continue;
        }
      }
    } catch (e) {
      _error = 'Error fetching translations: $e';
    }

    _isLoading = false;
    notifyListeners();
    return translations;
  }

  Future<Map<String, String>> fetchSurahTranslations(int surahNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final Map<String, String> translations = {};
    
    try {
      // Fetch translations for all available languages
      for (final lang in _availableLanguages.keys) {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/surah/$surahNumber/$lang'),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final verses = data['verses'] as List<dynamic>?;
            if (verses != null && verses.isNotEmpty) {
              final Map<String, String> ayahTranslations = {};
              for (final verse in verses) {
                final ayahNumber = verse['id']?.toString() ?? '';
                final translation = verse['translation'] ?? '';
                if (ayahNumber.isNotEmpty && translation.isNotEmpty) {
                  ayahTranslations[ayahNumber] = translation;
                }
              }
              if (ayahTranslations.isNotEmpty) {
                translations[lang] = json.encode(ayahTranslations);
              }
            }
          }
        } catch (e) {
          // Continue with other languages if one fails
          continue;
        }
      }
    } catch (e) {
      _error = 'Error fetching translations: $e';
    }

    _isLoading = false;
    notifyListeners();
    return translations;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
