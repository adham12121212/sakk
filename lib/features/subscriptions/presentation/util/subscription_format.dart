import 'package:flutter/widgets.dart';

import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/billing_cycle.dart';

/// "240 EGP" / "٢٤٠ ج.م" / "5.99 USD", in the app's digits.
String formatMoney(BuildContext context, double amount, String currency) {
  final l10n = AppLocalizations.of(context)!;
  final number = formatLocalizedAmount(Localizations.localeOf(context), amount);
  return '$number ${currency == 'EGP' ? l10n.currencyEgp : currency}';
}

/// "240 EGP / month".
String formatPricePerCycle(
  BuildContext context,
  double amount,
  String currency,
  BillingCycle cycle,
) {
  final l10n = AppLocalizations.of(context)!;
  final money = formatMoney(context, amount, currency);
  return cycle == BillingCycle.yearly
      ? l10n.pricePerYear(money)
      : l10n.pricePerMonth(money);
}

/// "Renews today", "Renews in 3 days"...
String renewalLabel(AppLocalizations l10n, int daysLeft) {
  if (daysLeft < 0) return l10n.renewalPassed;
  if (daysLeft == 0) return l10n.renewsToday;
  if (daysLeft == 1) return l10n.renewsTomorrow;
  return l10n.renewsInDays(
    daysLeft,
    formatLocalizedInt(Locale(l10n.localeName), daysLeft),
  );
}

/// Logo source when a service has no logo_url: Google's favicon service.
String? faviconUrl(String? domain) {
  if (domain == null || domain.isEmpty) return null;
  return 'https://www.google.com/s2/favicons?domain=${Uri.encodeComponent(domain)}&sz=128';
}
