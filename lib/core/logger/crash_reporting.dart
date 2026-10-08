import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../util/pii_masker.dart';

/// Sentry setup. Disabled in debug builds and when `SENTRY_DSN` is missing
/// from .env; in that case [appRunner] just runs directly.
///
/// Emails are never sent: default PII is off, the user is identified by
/// Supabase id only, and every event/breadcrumb is scrubbed in [_beforeSend]
/// and [_beforeBreadcrumb].
class CrashReporting {
  CrashReporting._();

  static Future<void> init({required FutureOr<void> Function() appRunner}) async {
    final dsn = dotenv.env['SENTRY_DSN']?.trim() ?? '';
    if (kDebugMode || dsn.isEmpty) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = kReleaseMode ? 'production' : 'profile';
        options.sendDefaultPii = false;
        options.beforeSend = _beforeSend;
        options.beforeBreadcrumb = _beforeBreadcrumb;
      },
      appRunner: appRunner,
    );
  }

  /// Keeps the Sentry user in sync with the Supabase session: set on sign-in
  /// (including a session restored at launch), cleared on sign-out and after
  /// account deletion. Call once, after `Supabase.initialize`.
  static void bindSupabaseUser(GoTrueClient auth) {
    _setUser(auth.currentUser);
    auth.onAuthStateChange.listen((data) => _setUser(data.session?.user));
  }

  static void _setUser(User? user) {
    Sentry.configureScope(
      (scope) => scope.setUser(user == null ? null : SentryUser(id: user.id)),
    );
  }

  // Sentry 9 data classes are mutable (copyWith is deprecated), so these
  // scrub the event/breadcrumb in place before it leaves the device.
  static FutureOr<SentryEvent?> _beforeSend(SentryEvent event, Hint hint) {
    // Never send anything but the id, even if an SDK integration adds more.
    final user = event.user;
    if (user != null) event.user = SentryUser(id: user.id);

    final message = event.message;
    if (message != null) {
      event.message = SentryMessage(
        PiiMasker.scrubEmails(message.formatted),
        template: message.template == null ? null : PiiMasker.scrubEmails(message.template!),
        params: message.params,
      );
    }

    for (final exception in event.exceptions ?? const <SentryException>[]) {
      final value = exception.value;
      if (value != null) exception.value = PiiMasker.scrubEmails(value);
    }

    // ignore: deprecated_member_use
    event.extra = _scrubMap(event.extra);
    event.breadcrumbs?.forEach(_scrubBreadcrumb);
    return event;
  }

  static Breadcrumb? _beforeBreadcrumb(Breadcrumb? crumb, Hint hint) {
    if (crumb != null) _scrubBreadcrumb(crumb);
    return crumb;
  }

  static void _scrubBreadcrumb(Breadcrumb crumb) {
    final message = crumb.message;
    if (message != null) crumb.message = PiiMasker.scrubEmails(message);
    crumb.data = _scrubMap(crumb.data);
  }

  /// Drops keys that name an email and scrubs email-like values from the rest.
  static Map<String, dynamic>? scrubData(Map<String, dynamic>? data) => _scrubMap(data);

  static Map<String, dynamic>? _scrubMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return {
      for (final entry in data.entries)
        if (!entry.key.toLowerCase().contains('email'))
          entry.key: entry.value is String ? PiiMasker.scrubEmails(entry.value as String) : entry.value,
    };
  }
}
