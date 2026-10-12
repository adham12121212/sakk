import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/util/localized_number.dart';
import 'package:sakk/features/subscriptions/presentation/util/subscription_format.dart';
import 'package:sakk/l10n/app_localizations_ar.dart';
import 'package:sakk/l10n/app_localizations_en.dart';

void main() {
  test('amounts drop .00 but keep real decimals, in the locale digits', () {
    expect(formatLocalizedAmount(const Locale('en'), 240), '240');
    expect(formatLocalizedAmount(const Locale('en'), 1350), '1,350');
    expect(formatLocalizedAmount(const Locale('en'), 5.99), '5.99');
    expect(formatLocalizedAmount(const Locale('en'), 100 / 12), '8.33');
    expect(formatLocalizedAmount(const Locale('ar'), 240), '٢٤٠');
  });

  test('renewal labels', () {
    final en = AppLocalizationsEn();
    expect(renewalLabel(en, 0), 'Renews today');
    expect(renewalLabel(en, 1), 'Renews tomorrow');
    expect(renewalLabel(en, 12), 'Renews in 12 days');
    expect(renewalLabel(en, -2), 'Renewal date passed');
    expect(renewalLabel(AppLocalizationsAr(), 2), 'يتجدد خلال يومين');
  });

  test('favicon url from the domain', () {
    expect(faviconUrl('netflix.com'), 'https://www.google.com/s2/favicons?domain=netflix.com&sz=128');
    expect(faviconUrl(null), isNull);
    expect(faviconUrl(''), isNull);
  });
}
