import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/exceptions.dart';

/// What the free plan limits by count (database triggers refuse more).
enum LimitedItem { products, subscriptions, installments }

/// What the free plan limits per day (the AI edge functions refuse more).
enum QuotaType { scan, chat }

/// Why the paywall opened; picks its headline.
enum PaywallReason {
  upgrade,
  scanLimit,
  chatLimit,
  productsLimit,
  subscriptionsLimit,
  installmentsLimit,
  monthlySummary,
  pdfReport,
}

/// The free plan's limit errors, as they travel through the app.
///
/// The database raises `LIMIT_REACHED:<item>` when a free user adds more
/// than their plan allows, and the AI functions answer 402 with
/// `{"code": "LIMIT_REACHED", "type": "scan" | "chat"}`. Data sources turn
/// either into a [ServerException] whose message is [code] (e.g.
/// `limit_reached:products`), which `userFacingError` explains, and report
/// it on [events] so the app can open the paywall wherever it happened.
class ProLimit {
  ProLimit._();

  static const _prefix = 'limit_reached:';

  /// Kind for Pro's daily fair-use cap (no paywall for it).
  static const fairUse = 'fair_use';

  static String code(String kind) => '$_prefix$kind';

  /// `products`, `scan`... for a limit code, null for any other message.
  static String? kindOf(String? message) =>
      message != null && message.startsWith(_prefix) ? message.substring(_prefix.length) : null;

  static final _events = StreamController<PaywallReason>.broadcast();

  /// A limit was hit somewhere; the app shell opens the paywall.
  static Stream<PaywallReason> get events => _events.stream;

  /// Something that counts toward the limits changed (an item added or
  /// deleted, a scan or chat used); the plan status re-reads its counters.
  static final _usageChanged = StreamController<void>.broadcast();
  static Stream<void> get usageChanged => _usageChanged.stream;
  static void notifyUsageChanged() => _usageChanged.add(null);

  /// The limit code for [error] if it's a limit error (and reports it on
  /// [events]), otherwise null.
  static String? codeFor(Object error) {
    final kind = _kindOfError(error);
    if (kind == null) return null;
    final reason = reasonFor(kind);
    if (reason != null) _events.add(reason);
    return code(kind);
  }

  /// For a data source's catch block: the limit error for [error] if it is
  /// one, otherwise a [ServerException] with [fallback].
  static ServerException exceptionFor(Object error, String fallback) =>
      ServerException(codeFor(error) ?? fallback);

  static String? _kindOfError(Object error) {
    if (error is FunctionException) {
      final details = error.details;
      if (error.status == 402 && details is Map && details['code'] == 'LIMIT_REACHED') {
        // A Pro user at the fair-use cap: no paywall, just "try tomorrow".
        if (details['pro'] == true) return fairUse;
        return details['type']?.toString() ?? 'scan';
      }
      return null;
    }
    // PostgrestException's message, or one wrapped in another error's text.
    final match = RegExp(r'LIMIT_REACHED:(\w+)').firstMatch(
      error is PostgrestException ? error.message : error.toString(),
    );
    return match?.group(1);
  }

  static PaywallReason? reasonFor(String kind) => switch (kind) {
        'scan' => PaywallReason.scanLimit,
        'chat' => PaywallReason.chatLimit,
        'products' => PaywallReason.productsLimit,
        'subscriptions' => PaywallReason.subscriptionsLimit,
        'installments' => PaywallReason.installmentsLimit,
        _ => null,
      };

  static PaywallReason reasonForItem(LimitedItem item) => switch (item) {
        LimitedItem.products => PaywallReason.productsLimit,
        LimitedItem.subscriptions => PaywallReason.subscriptionsLimit,
        LimitedItem.installments => PaywallReason.installmentsLimit,
      };
}
