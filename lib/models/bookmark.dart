class Bookmark {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String surahNameArabic;
  final DateTime createdAt;
  final String? note;

  Bookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'surahNameArabic': surahNameArabic,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      surahNumber: json['surahNumber'],
      ayahNumber: json['ayahNumber'],
      surahName: json['surahName'],
      surahNameArabic: json['surahNameArabic'],
      createdAt: DateTime.parse(json['createdAt']),
      note: json['note'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark &&
        other.surahNumber == surahNumber &&
        other.ayahNumber == ayahNumber;
  }

  @override
  int get hashCode => surahNumber.hashCode ^ ayahNumber.hashCode;
}
