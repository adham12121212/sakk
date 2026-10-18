import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/pro/domain/entities/pro_status.dart';
import 'package:sakk/features/pro/presentation/widgets/plan_badge.dart';
import 'package:sakk/l10n/app_localizations.dart';

ProStatus pro({String product = 'sakk_pro:monthly', bool trial = false, bool billing = false, DateTime? until}) =>
    ProStatus(
      isPro: true,
      entitlement: ProEntitlement(
        isActive: true,
        productId: product,
        isTrial: trial,
        billingIssue: billing,
        expiresAt: until,
      ),
    );

Widget app(Widget child, {Locale locale = const Locale('ar'), bool dark = false}) => MaterialApp(
      locale: locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  final now = DateTime(2026, 10, 18, 12);

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('$mode: each plan has its label', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      final cases = {
        const ProStatus(): l10n.planBadgeFree,
        pro(): l10n.planBadgePro,
        pro(product: 'sakk_pro:yearly'): l10n.planBadgeYearly,
        pro(billing: true): l10n.planBadgeBillingIssue,
      };
      for (final MapEntry(key: status, value: label) in cases.entries) {
        await tester.pumpWidget(app(PlanBadge(status: status, now: now), dark: dark));
        expect(find.text(label), findsOneWidget, reason: '${status.plan}');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('$mode: trial shows the days left', (tester) async {
      await tester.pumpWidget(app(
        PlanBadge(status: pro(trial: true, until: now.add(const Duration(days: 5))), now: now),
        dark: dark,
      ));
      // "Pro – تجربة · فاضل ٥ يوم" in Arabic digits.
      expect(find.textContaining('Pro – تجربة'), findsOneWidget);
      expect(find.textContaining('٥'), findsOneWidget);
    });
  }

  testWidgets('English trial label', (tester) async {
    await tester.pumpWidget(app(
      PlanBadge(status: pro(trial: true, until: now.add(const Duration(days: 5))), now: now),
      locale: const Locale('en'),
    ));
    expect(find.text('Pro – Trial · 5 days left'), findsOneWidget);
  });

  testWidgets('tapping a free badge calls onTap; small size fits a narrow row', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(SizedBox(
      width: 80,
      child: PlanBadge(status: const ProStatus(), size: PlanBadgeSize.small, onTap: () => taps++),
    )));
    await tester.tap(find.byType(PlanBadge));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
