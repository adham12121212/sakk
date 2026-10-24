import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/paper.dart';

/// "Nov 5, 2026" / "٥ نوفمبر ٢٠٢٦", with the app's digits.
String formatPaperDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  final tag = locale.languageCode == 'ar' ? 'ar_EG' : locale.toLanguageTag();
  return DateFormat.yMMMd(tag).format(date);
}

/// "Valid until Nov 5, 2026", "Expires in 12 days", "Expired on ...".
String paperExpiryLabel(BuildContext context, Paper paper, DateTime today) {
  final l10n = AppLocalizations.of(context)!;
  final expiry = paper.expiryDate;
  final days = paper.daysLeft(today);
  if (expiry == null || days == null) return l10n.paperNoExpiryDate;
  final date = formatPaperDate(context, expiry);
  return switch (paper.status(today)) {
    PaperStatus.expired => l10n.paperExpiredOn(date),
    PaperStatus.expiringSoon when days == 0 => l10n.paperExpiresToday,
    PaperStatus.expiringSoon => l10n.paperExpiresInDays(
      days,
      formatLocalizedInt(Localizations.localeOf(context), days),
    ),
    _ => l10n.paperValidUntil(date),
  };
}

/// Highlight for the expiry line: red once expired, amber when it's soon.
Color? paperStatusColor(BuildContext context, PaperStatus status) =>
    switch (status) {
      PaperStatus.expired => context.palette.danger,
      PaperStatus.expiringSoon => context.palette.warning,
      _ => null,
    };
