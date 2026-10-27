import 'package:flutter/widgets.dart' show Locale;

import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../papers/domain/entities/paper.dart';
import '../../../papers/presentation/util/paper_ui.dart';
import '../../domain/entities/notification_message.dart';

/// The title of a [kind] of reminder in [l10n]'s language.
String notificationTitle(AppLocalizations l10n, NotificationKind kind) {
  return switch (kind) {
    NotificationKind.warrantyExpiring => l10n.notifExpiringTitle,
    NotificationKind.warrantyExpired => l10n.notifExpiredTitle,
    NotificationKind.subscriptionRenewal => l10n.notifRenewalTitle,
    NotificationKind.subscriptionRenewed => l10n.notifRenewedTitle,
    NotificationKind.installmentDueSoon => l10n.notifInstallmentDueSoonTitle,
    NotificationKind.installmentDueToday => l10n.notifInstallmentDueTodayTitle,
    NotificationKind.paperExpiring => l10n.notifPaperExpiringTitle,
    NotificationKind.paperExpired => l10n.notifPaperExpiredTitle,
  };
}

/// The body of [message] in [l10n]'s language, numbers in its digits. The
/// reminder services build their text with this too, so a notification
/// reads the same in the list as it did when it arrived.
String notificationBody(AppLocalizations l10n, NotificationMessage message) {
  final locale = Locale(l10n.localeName);
  final args = message.args;
  final days = (args['days'] as num?)?.toInt() ?? 0;
  final daysText = formatLocalizedInt(locale, days);
  String money(String key) {
    final amount = formatLocalizedAmount(locale, (args[key] as num).toDouble());
    final currency = args['currency'] as String? ?? 'EGP';
    return '$amount ${currency == 'EGP' ? l10n.currencyEgp : currency}';
  }

  switch (message.kind) {
    case NotificationKind.warrantyExpiring:
      return l10n.notifExpiringInDays(
        days,
        daysText,
        args['product'] as String,
      );
    case NotificationKind.warrantyExpired:
      return l10n.notifExpiredBody(args['product'] as String);
    case NotificationKind.subscriptionRenewal:
      return l10n.notifRenewalBody(
        days,
        daysText,
        args['name'] as String,
        money('price'),
      );
    case NotificationKind.subscriptionRenewed:
      return l10n.notifRenewedBody(
        days,
        daysText,
        args['name'] as String,
        money('price'),
      );
    case NotificationKind.installmentDueSoon:
    case NotificationKind.installmentDueToday:
      return l10n.notifInstallmentDueBody(
        days,
        daysText,
        args['name'] as String,
        money('amount'),
      );
    case NotificationKind.paperExpiring:
    case NotificationKind.paperExpired:
      final title = args['title'] as String?;
      final name = title != null && title.isNotEmpty
          ? title
          : PaperUi.kindName(
              l10n,
              PaperKind.values.asNameMap()[args['paperKind']] ??
                  PaperKind.other,
            );
      if (days < 0) return l10n.notifPaperExpiredBody(name);
      if (days == 0) return l10n.notifPaperExpiresTodayBody(name);
      return l10n.notifPaperExpiringBody(days, daysText, name);
  }
}
