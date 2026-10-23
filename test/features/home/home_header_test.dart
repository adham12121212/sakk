import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/home/presentation/widgets/home_header.dart';
import 'package:sakk/l10n/app_localizations.dart';

Widget app(Locale locale) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(
    locale: locale,
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: HomeHeader(userName: 'Adham', unreadNotificationCount: 2),
    ),
  ),
);

void main() {
  for (final (locale, rtl) in [
    (const Locale('en'), false),
    (const Locale('ar'), true),
  ]) {
    testWidgets(
      '${locale.languageCode}: profile, name, then search and notifications',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(locale));

        final l10n = await AppLocalizations.delegate.load(locale);
        double x(Finder f) => tester.getCenter(f).dx;
        final avatar = x(find.bySemanticsLabel(l10n.openProfile));
        final name = x(find.text('Adham'));
        final search = x(find.bySemanticsLabel(l10n.search));
        final bell = x(find.bySemanticsLabel(RegExp(l10n.notifications)));

        // Reading order: avatar → name → search → notifications. In Arabic the
        // same order runs right to left.
        final order = [avatar, name, search, bell];
        final expected = [...order]..sort();
        expect(order, rtl ? expected.reversed.toList() : expected);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
