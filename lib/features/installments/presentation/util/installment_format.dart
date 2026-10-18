import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../subscriptions/presentation/util/subscription_format.dart';

export '../../../subscriptions/presentation/util/subscription_format.dart'
    show formatMoney;

/// Installments this close to their due date are highlighted.
const installmentSoonDays = 3;

/// "Nov 5, 2026" / "٥ نوفمبر ٢٠٢٦", with the app's digits.
String formatInstallmentDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  final tag = locale.languageCode == 'ar' ? 'ar_EG' : locale.toLanguageTag();
  return DateFormat.yMMMd(tag).format(date);
}

/// A count in the app's digits.
String formatCount(BuildContext context, int value) =>
    formatLocalizedInt(Localizations.localeOf(context), value);

/// "Due today", "Due in 3 days", "Overdue by 2 days"...
String dueLabel(BuildContext context, int daysLeft) {
  final l10n = AppLocalizations.of(context)!;
  if (daysLeft == 0) return l10n.installmentDueToday;
  if (daysLeft == 1) return l10n.installmentDueTomorrow;
  final days = daysLeft.abs();
  final text = formatCount(context, days);
  return daysLeft < 0
      ? l10n.installmentOverdueBy(days, text)
      : l10n.installmentDueInDays(days, text);
}

/// Red once overdue, amber when due soon, null otherwise.
Color? dueColor(BuildContext context, int daysLeft) {
  if (daysLeft < 0) return context.palette.danger;
  if (daysLeft <= installmentSoonDays) return context.palette.warning;
  return null;
}

/// "4 of 12 paid".
String paidOfLabel(BuildContext context, int paid, int total) =>
    AppLocalizations.of(context)!.installmentsPaidOf(
      formatCount(context, paid),
      formatCount(context, total),
    );

/// The EGP amount first (the app's currency), then any others: "1,200 ج.م
/// + 50 USD". Never adds different currencies together.
String formatTotals(BuildContext context, Map<String, double> totals) {
  if (totals.isEmpty) return formatMoney(context, 0, 'EGP');
  final ordered = [
    if (totals.containsKey('EGP')) 'EGP',
    ...totals.keys.where((c) => c != 'EGP'),
  ];
  return [for (final c in ordered) formatMoney(context, totals[c]!, c)].join(' + ');
}
