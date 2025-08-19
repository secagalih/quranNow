import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark.dart';
import '../services/toast_service.dart';

class BookmarkProvider extends ChangeNotifier {
  static const String _bookmarksKey = 'bookmarks';
  final Set<Bookmark> _bookmarks = {};
  bool _isLoading = false;

  Set<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey);
      
      if (bookmarksJson != null) {
        final List<dynamic> bookmarksList = json.decode(bookmarksJson);
        _bookmarks.clear();
        _bookmarks.addAll(
          bookmarksList.map((json) => Bookmark.fromJson(json)).toSet(),
        );
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = json.encode(
        _bookmarks.map((bookmark) => bookmark.toJson()).toList(),
      );
      await prefs.setString(_bookmarksKey, bookmarksJson);
    } catch (e) {
      print('Error saving bookmarks: $e');
    }
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _bookmarks.any(
      (bookmark) => bookmark.surahNumber == surahNumber && bookmark.ayahNumber == ayahNumber,
    );
  }

  Future<void> toggleBookmark(int surahNumber, int ayahNumber, String surahName, String surahNameArabic) async {
    final existingBookmark = _bookmarks.lookup(
      Bookmark(surahNumber: surahNumber, ayahNumber: ayahNumber, surahName: '', surahNameArabic: '', createdAt: DateTime.now()),
    );

    if (existingBookmark != null) {
      // Remove bookmark
      _bookmarks.remove(existingBookmark);
      await _saveBookmarks();
      ToastService.showSuccess('Bookmark removed');
    } else {
      // Add bookmark
      final bookmark = Bookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        surahName: surahName,
        surahNameArabic: surahNameArabic,
        createdAt: DateTime.now(),
      );
      _bookmarks.add(bookmark);
      await _saveBookmarks();
      ToastService.showSuccess('Bookmark added');
    }
    
    notifyListeners();
  }

  Future<void> addBookmarkWithNote(int surahNumber, int ayahNumber, String surahName, String surahNameArabic, String note) async {
    final bookmark = Bookmark(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      surahNameArabic: surahNameArabic,
      createdAt: DateTime.now(),
      note: note,
    );
    
    _bookmarks.add(bookmark);
    await _saveBookmarks();
    ToastService.showSuccess('Bookmark added with note');
    notifyListeners();
  }

  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final bookmarkToRemove = _bookmarks.lookup(
      Bookmark(surahNumber: surahNumber, ayahNumber: ayahNumber, surahName: '', surahNameArabic: '', createdAt: DateTime.now()),
    );
    
    if (bookmarkToRemove != null) {
      _bookmarks.remove(bookmarkToRemove);
      await _saveBookmarks();
      ToastService.showSuccess('Bookmark removed');
      notifyListeners();
    }
  }

  Future<void> clearAllBookmarks() async {
    _bookmarks.clear();
    await _saveBookmarks();
    ToastService.showSuccess('All bookmarks cleared');
    notifyListeners();
  }

  List<Bookmark> getBookmarksForSurah(int surahNumber) {
    return _bookmarks
        .where((bookmark) => bookmark.surahNumber == surahNumber)
        .toList()
      ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
  }

  List<Bookmark> getBookmarksByDate() {
    return _bookmarks.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int getBookmarkCountForSurah(int surahNumber) {
    return _bookmarks.where((bookmark) => bookmark.surahNumber == surahNumber).length;
  }

  bool hasBookmarks() {
    return _bookmarks.isNotEmpty;
  }
}
