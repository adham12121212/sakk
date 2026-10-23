import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats [value] with the digits of [locale].
///
/// intl's plain `ar` locale uses Latin digits; only regional variants such as
/// `ar_EG` use Arabic-Indic ones. The app's Arabic locale has no region and the
/// app is Egyptian (EGP), so Arabic numbers are formatted as `ar_EG`
/// (e.g. 12 -> ١٢).
String formatLocalizedInt(Locale locale, int value) {
  return NumberFormat.decimalPattern(_numberTag(locale)).format(value);
}

/// Formats an amount of money with the digits of [locale]: whole amounts
/// without decimals (240), others with two (5.99).
String formatLocalizedAmount(Locale locale, double value) {
  final rounded = (value * 100).round() / 100;
  final digits = rounded == rounded.truncateToDouble() ? 0 : 2;
  return NumberFormat.decimalPatternDigits(
    locale: _numberTag(locale),
    decimalDigits: digits,
  ).format(rounded);
}

String _numberTag(Locale locale) {
  return locale.languageCode == 'ar' && (locale.countryCode ?? '').isEmpty
      ? 'ar_EG'
      : locale.toString();
}

/// Badge text for [count]: the number in locale digits, capped at "[max]+".
String formatBadgeCount(Locale locale, int count, {int max = 9}) {
  return count > max
      ? '${formatLocalizedInt(locale, max)}+'
      : formatLocalizedInt(locale, count);
}

/// Reads a number typed with Latin or Arabic-Indic digits and a "." , ","
/// or Arabic "٫" decimal separator. Null when it isn't a number.
double? parseLocalizedNumber(String raw) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final normalized = raw.trim().split('').map((c) {
    final i = arabic.indexOf(c);
    if (i >= 0) return '$i';
    return c == '٫' || c == ',' ? '.' : c;
  }).join();
  return double.tryParse(normalized);
}
