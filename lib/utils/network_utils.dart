import 'package:dio/dio.dart';

class NetworkUtils {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'QuranNow/1.0',
      'Accept': 'application/json',
    },
  ));

  /// Check if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final response = await _dio.get('https://www.google.com');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if the API endpoint is accessible
  static Future<bool> isApiAccessible() async {
    try {
      final response = await _dio.get('https://alquran-api.pages.dev/api/quran');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get a user-friendly error message from DioException
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Request timeout: Please try again.';
        case DioExceptionType.connectionError:
          return 'Network error: Please check your internet connection and try again.';
        case DioExceptionType.badResponse:
          return 'Server error: ${error.response?.statusCode}';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error: ${error.message}';
      }
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }

  /// Check if error is a network connectivity issue
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.sendTimeout;
    }
    return error.toString().contains('SocketException') ||
           error.toString().contains('Failed host lookup') ||
           error.toString().contains('Network is unreachable');
  }
}
