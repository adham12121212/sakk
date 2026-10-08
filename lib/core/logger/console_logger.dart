import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../util/pii_masker.dart';
import 'app_logger.dart';
import 'crash_reporting.dart';

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
    _reportToSentry(message, error, stackTrace, data);
  }

  // No-op when Sentry isn't initialized (debug builds or no SENTRY_DSN).
  void _reportToSentry(String message, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data) {
    void addLogContext(Scope scope) {
      scope.setContexts('log', {
        'message': PiiMasker.scrubEmails(message),
        ...?CrashReporting.scrubData(data),
      });
    }

    if (error != null) {
      Sentry.captureException(error, stackTrace: stackTrace, withScope: addLogContext);
    } else {
      Sentry.captureMessage(
        PiiMasker.scrubEmails(message),
        level: SentryLevel.error,
        withScope: addLogContext,
      );
    }
  }

  void _log(String level, String message, Map<String, dynamic>? data) {
    final buffer = StringBuffer('[$level] $message');
    if (data != null && data.isNotEmpty) {
      buffer.write(' | ${data.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
    }
    debugPrint(buffer.toString());
  }
}