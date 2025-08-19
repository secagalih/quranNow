import 'package:flutter/material.dart';

class ErrorMessageService {
  static ErrorInfo getErrorInfo(String error, {String? context}) {
    // Check if it's a network error
    if (_isNetworkError(error)) {
      return ErrorInfo(
        title: 'Connection Problem',
        message: 'Unable to connect to the server. Please check your internet connection.',
        subtitle: 'Make sure you have a stable internet connection and try again.',
        icon: Icons.wifi_off,
        retryText: 'Try Again',
        showGoHome: context != 'home',
      );
    }

    // Check if it's a timeout error
    if (_isTimeoutError(error)) {
      return ErrorInfo(
        title: 'Request Timeout',
        message: 'The request is taking too long to complete.',
        subtitle: 'This might be due to a slow internet connection. Please try again.',
        icon: Icons.timer_off,
        retryText: 'Retry',
        showGoHome: context != 'home',
      );
    }

    // Check if it's a server error
    if (_isServerError(error)) {
      return ErrorInfo(
        title: 'Server Problem',
        message: 'The server is temporarily unavailable.',
        subtitle: 'Please try again in a few moments. If the problem persists, check back later.',
        icon: Icons.cloud_off,
        retryText: 'Retry',
        showGoHome: context != 'home',
      );
    }

    // Check if it's a data not found error
    if (_isDataNotFoundError(error)) {
      return ErrorInfo(
        title: 'Content Not Available',
        message: context == 'surah' 
            ? 'This surah is not available offline. Please connect to the internet to load it.'
            : 'The requested content is not available.',
        subtitle: context == 'surah'
            ? 'You need to load this surah while online to cache it for offline reading.'
            : 'Make sure you have a stable internet connection.',
        icon: Icons.cloud_download,
        retryText: 'Load Online',
        showGoHome: context != 'home',
      );
    }

    // Check if it's a cache-related error
    if (_isCacheError(error)) {
      return ErrorInfo(
        title: 'Offline Data Problem',
        message: 'There\'s an issue with your offline data.',
        subtitle: 'Try connecting to the internet to refresh your data, or clear cache in settings.',
        icon: Icons.storage,
        retryText: 'Refresh Data',
        showGoHome: context != 'home',
      );
    }

    // Generic error
    return ErrorInfo(
      title: context == 'surah' ? 'Failed to Load Surah' : 'Something Went Wrong',
      message: context == 'surah' 
          ? 'Unable to load this surah. Please check your connection and try again.'
          : error.isNotEmpty ? error : 'An unexpected error occurred.',
      subtitle: context == 'surah'
          ? 'Make sure you have internet connection or this surah is cached for offline reading.'
          : 'Please try again. If the problem persists, restart the app.',
      icon: Icons.error_outline,
      retryText: 'Try Again',
      showGoHome: context != 'home',
    );
  }

  static bool _isNetworkError(String error) {
    final networkKeywords = [
      'network error',
      'no internet',
      'connection error',
      'socketexception',
      'failed host lookup',
      'network is unreachable',
    ];
    
    final lowerError = error.toLowerCase();
    return networkKeywords.any((keyword) => lowerError.contains(keyword));
  }

  static bool _isTimeoutError(String error) {
    final timeoutKeywords = [
      'timeout',
      'request timeout',
      'connection timeout',
      'receive timeout',
    ];
    
    final lowerError = error.toLowerCase();
    return timeoutKeywords.any((keyword) => lowerError.contains(keyword));
  }

  static bool _isServerError(String error) {
    final serverKeywords = [
      'server error',
      'status code: 5',
      'internal server error',
      'bad gateway',
      'service unavailable',
    ];
    
    final lowerError = error.toLowerCase();
    return serverKeywords.any((keyword) => lowerError.contains(keyword));
  }

  static bool _isDataNotFoundError(String error) {
    final notFoundKeywords = [
      'no offline data',
      'not found',
      'status code: 404',
      'not available',
      'no cached data',
    ];
    
    final lowerError = error.toLowerCase();
    return notFoundKeywords.any((keyword) => lowerError.contains(keyword));
  }

  static bool _isCacheError(String error) {
    final cacheKeywords = [
      'cache',
      'storage',
      'local data',
      'offline data',
    ];
    
    final lowerError = error.toLowerCase();
    return cacheKeywords.any((keyword) => lowerError.contains(keyword));
  }
}

class ErrorInfo {
  final String title;
  final String message;
  final String? subtitle;
  final IconData icon;
  final String retryText;
  final bool showGoHome;

  ErrorInfo({
    required this.title,
    required this.message,
    this.subtitle,
    required this.icon,
    required this.retryText,
    this.showGoHome = false,
  });
}
