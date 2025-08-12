import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import '../lib/utils/network_utils.dart';

void main() {
  group('Network Utils Tests', () {
    test('should handle DioException correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
        message: 'Connection failed',
      );

      final errorMessage = NetworkUtils.getErrorMessage(dioException);
      expect(errorMessage, contains('Network error: Please check your internet connection'));
    });

    test('should handle timeout exceptions', () {
      final timeoutException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      );

      final errorMessage = NetworkUtils.getErrorMessage(timeoutException);
      expect(errorMessage, contains('Request timeout'));
    });

    test('should identify network errors correctly', () {
      final networkException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final isNetworkError = NetworkUtils.isNetworkError(networkException);
      expect(isNetworkError, isTrue);
    });

    test('should handle non-DioException errors', () {
      final genericError = Exception('Generic error');
      final errorMessage = NetworkUtils.getErrorMessage(genericError);
      expect(errorMessage, contains('An unexpected error occurred'));
    });
  });
}
