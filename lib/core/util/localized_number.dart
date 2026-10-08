import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats [value] with the digits of [locale].
///
/// intl's plain `ar` locale uses Latin digits; only regional variants such as
/// `ar_EG` use Arabic-Indic ones. The app's Arabic locale has no region and the
/// app is Egyptian (EGP), so Arabic numbers are formatted as `ar_EG`
/// (e.g. 12 -> ١٢).
String formatLocalizedInt(Locale locale, int value) {
  final tag = locale.languageCode == 'ar' && (locale.countryCode ?? '').isEmpty
      ? 'ar_EG'
      : locale.toString();
  return NumberFormat.decimalPattern(tag).format(value);
}

/// Badge text for [count]: the number in locale digits, capped at "[max]+".
String formatBadgeCount(Locale locale, int count, {int max = 9}) {
  return count > max
      ? '${formatLocalizedInt(locale, max)}+'
      : formatLocalizedInt(locale, count);
}
