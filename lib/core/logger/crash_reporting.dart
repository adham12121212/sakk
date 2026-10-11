import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/pii_masker.dart';

/// Firebase Crashlytics setup. Collection is off in debug builds. Call
/// [init] right after `Firebase.initializeApp`.
///
/// Emails are never sent: the user is identified by Supabase id only, and
/// every Dart error, log message and data map goes through [PiiMasker]
/// before it is handed to Crashlytics. Native crashes are reported as-is.
class CrashReporting {
  CrashReporting._();

  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  static Future<void> init() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toDescription(),
        fatal: true,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Keeps the Crashlytics user in sync with the Supabase session: set on
  /// sign-in (including a session restored at launch), cleared on sign-out
  /// and after account deletion. Call once, after `Supabase.initialize`.
  static void bindSupabaseUser(GoTrueClient auth) {
    _setUser(auth.currentUser);
    auth.onAuthStateChange.listen((data) => _setUser(data.session?.user));
  }

  static void _setUser(User? user) {
    _crashlytics.setUserIdentifier(user?.id ?? '');
  }

  /// Reports [error] with its message, [reason] and [data] scrubbed of
  /// emails and private links.
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? data,
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      _ScrubbedError(error),
      stackTrace,
      reason: reason == null ? null : PiiMasker.scrub(reason),
      information: [
        for (final entry in (scrubData(data) ?? const {}).entries)
          '${entry.key}: ${entry.value}',
      ],
      fatal: fatal,
    );
  }

  /// Drops keys that name an email and scrubs email-like values from the rest.
  static Map<String, dynamic>? scrubData(Map<String, dynamic>? data) {
    if (data == null) return null;
    return {
      for (final entry in data.entries)
        if (!entry.key.toLowerCase().contains('email'))
          entry.key: entry.value is String ? PiiMasker.scrub(entry.value as String) : entry.value,
    };
  }
}

/// Wraps an error so Crashlytics reports its scrubbed text. Keeps the
/// original type name so issues still group by error type.
class _ScrubbedError {
  _ScrubbedError(Object error)
      : _text = PiiMasker.scrub(error.toString()),
        _type = error.runtimeType.toString();

  final String _text;
  final String _type;

  @override
  String toString() => _text.startsWith(_type) ? _text : '$_type: $_text';
}
