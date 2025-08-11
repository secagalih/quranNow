class Ayah {
  final int number; // global ayah number
  final int surahNumber; // parent surah id
  final String text; // Arabic text
  final String textArabic; // alias to Arabic text
  final String translation; // may be empty with current endpoint
  final Map<String, String> translations; // multiple language translations
  final String audioUrl; // may be empty with current endpoint
  final int juz;
  final int page;
  final int ruku;
  final int hizbQuarter;

  Ayah({
    required this.number,
    required this.surahNumber,
    required this.text,
    required this.textArabic,
    required this.translation,
    required this.translations,
    required this.audioUrl,
    required this.juz,
    required this.page,
    required this.ruku,
    required this.hizbQuarter,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    // New Al-Quran API Ayah fields include: id, text, translation
    final text = (json['text'] ?? '').toString();
    final translation = (json['translation'] ?? '').toString();
    
    // Initialize translations map
    final Map<String, String> translations = {};
    if (translation.isNotEmpty) {
      translations['en'] = translation;
    }
    
    return Ayah(
      number: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      surahNumber: 0, // Will be set by the provider
      text: text,
      textArabic: text,
      translation: translation,
      translations: translations,
      audioUrl: '', // Audio not available in this API
      juz: 0, // Not available in this API
      page: 0, // Not available in this API
      ruku: 0, // Not available in this API
      hizbQuarter: 0, // Not available in this API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'surahNumber': surahNumber,
      'text': text,
      'textArabic': textArabic,
      'translation': translation,
      'translations': translations,
      'audioUrl': audioUrl,
      'juz': juz,
      'page': page,
      'ruku': ruku,
      'hizbQuarter': hizbQuarter,
    };
  }

  String getTranslation(String languageCode) {
    return translations[languageCode] ?? translation;
  }
}
