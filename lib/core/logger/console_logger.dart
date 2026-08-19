import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class ConsoleLogger implements AppLogger {
  @override
  void debug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) _log('DEBUG', message, data);
  }

  @override
  void info(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) _log('INFO', message, data);
  }

  @override
  void warning(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) _log('WARNING', message, data);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _log('ERROR', message, data);
      if (error != null) debugPrint('  ↳ error: $error');
      if (stackTrace != null) debugPrint('  ↳ stackTrace: $stackTrace');
    }
    // TODO: forward to Sentry / Crashlytics here for release builds
  }

  void _log(String level, String message, Map<String, dynamic>? data) {
    final buffer = StringBuffer('[$level] $message');
    if (data != null && data.isNotEmpty) {
      buffer.write(' | ${data.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }
    debugPrint(buffer.toString());
  }
}