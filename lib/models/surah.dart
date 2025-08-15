class Surah {
  final int number;
  final String name; // raw API name (Arabic)
  final String nameArabic; // alias to Arabic name
  final String nameEnglish;
  final String revelationType;
  final int numberOfAyahs;
  final String description;

  Surah({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.description,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    // New Al-Quran API fields:
    // id, name (Arabic), transliteration, translation, type, total_verses
    final arabicName = (json['name'] ?? '').toString();
    final englishName = (json['transliteration'] ?? '').toString();
    final englishTrans = (json['translation'] ?? '').toString();
    return Surah(
      number: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: arabicName,
      nameArabic: arabicName,
      nameEnglish: englishName,
      revelationType: (json['type'] ?? '').toString(),
      numberOfAyahs: json['total_verses'] is int ? json['total_verses'] as int : int.tryParse('${json['total_verses']}') ?? 0,
      description: englishTrans,
    );
  }

  factory Surah.fromEquranJson(Map<String, dynamic> json) {
    // EQuran.id API v2 fields:
    // nomor, nama, namaLatin, jumlahAyat, tempatTurun, arti, deskripsi
    final arabicName = (json['nama'] ?? '').toString();
    final latinName = (json['namaLatin'] ?? '').toString();
    final meaning = (json['arti'] ?? '').toString();
    final description = (json['deskripsi'] ?? '').toString();
    
    return Surah(
      number: json['nomor'] is int ? json['nomor'] as int : int.tryParse('${json['nomor']}') ?? 0,
      name: arabicName,
      nameArabic: arabicName,
      nameEnglish: latinName,
      revelationType: (json['tempatTurun'] ?? '').toString(),
      numberOfAyahs: json['jumlahAyat'] is int ? json['jumlahAyat'] as int : int.tryParse('${json['jumlahAyat']}') ?? 0,
      description: meaning.isNotEmpty ? meaning : description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'nameArabic': nameArabic,
      'nameEnglish': nameEnglish,
      'revelationType': revelationType,
      'numberOfAyahs': numberOfAyahs,
      'description': description,
    };
  }
}
