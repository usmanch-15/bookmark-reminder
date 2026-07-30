import 'dart:async';

/// Retries an async operation with exponential backoff.
/// Use for network calls where a transient failure is common.
class RetryWrapper {
  static Future<T> run<T>(
      Future<T> Function() operation, {
        int maxAttempts = 3,
        Duration initialDelay = const Duration(milliseconds: 500),
      }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }
}