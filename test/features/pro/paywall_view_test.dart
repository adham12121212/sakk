import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/pro/data/pro_status_data_source.dart';
import 'package:sakk/features/pro/domain/entities/pro_status.dart';
import 'package:sakk/features/pro/domain/pro_limit.dart';
import 'package:sakk/features/pro/presentation/cubit/paywall_cubit.dart';
import 'package:sakk/features/pro/presentation/cubit/pro_cubit.dart';
import 'package:sakk/features/pro/presentation/views/paywall_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

import 'pro_cubit_test.dart' show FakeStore, NoLog;

class _Server implements ProStatusDataSource {
  @override
  Future<ProStatus> getStatus() async => const ProStatus(
        scan: Quota(used: 3, limit: 3, remaining: 0),
        chat: Quota(used: 0, limit: 5, remaining: 5),
        items: {
          LimitedItem.products: ItemUsage(count: 5, limit: 5),
          LimitedItem.subscriptions: ItemUsage(count: 0, limit: 3),
          LimitedItem.installments: ItemUsage(count: 0, limit: 1),
        },
      );
}

void main() {
  late ProCubit pro;
  late FakeStore store;
  late StreamController<String?> users;

  setUp(() async {
    store = FakeStore();
    users = StreamController<String?>();
    pro = ProCubit(_Server(), store, userIdChanges: users.stream, logger: NoLog(), usageChanged: const Stream.empty());
    getIt.registerSingleton<ProCubit>(pro);
    users.add('user-1');
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('ar'), bool dark = false}) async {
    // Narrow phone width; tall so the whole list is built.
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => PaywallCubit(store, pro, NoLog()),
        child: const PaywallView(reason: PaywallReason.scanLimit),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets('Arabic ${dark ? 'dark' : 'light'}: limits, store prices, saving, trial and Play disclosures', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      await pump(tester, dark: dark);

      expect(find.text(l10n.paywallHeadlineScan), findsOneWidget);
      // Free limits come from the server; ٣ في اليوم for scans.
      expect(find.text(l10n.valuePerDay('٣')), findsOneWidget);
      // Prices exactly as the store formats them, never hard-coded.
      expect(find.text(l10n.pricePerYear('EGP 249')), findsOneWidget);
      expect(find.text(l10n.pricePerMonth('EGP 29')), findsOneWidget);
      expect(find.text(l10n.savePercent('٢٨')), findsOneWidget);
      expect(find.text(l10n.bestValue), findsOneWidget);
      expect(find.text(l10n.featurePdfReport), findsOneWidget);
      expect(find.text(l10n.startFreeTrial), findsOneWidget);

      expect(find.text(l10n.restorePurchases), findsOneWidget);
      expect(find.text(l10n.termsOfService), findsOneWidget);
      expect(find.text(l10n.privacyPolicy), findsOneWidget);
      expect(find.text(l10n.autoRenewDisclosure), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('picking monthly drops the trial button when monthly has none', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pump(tester, locale: const Locale('en'));
    await tester.tap(find.text(l10n.planMonthly));
    await tester.pumpAndSettle();
    expect(find.text(l10n.subscribe), findsOneWidget);
    expect(find.text(l10n.startFreeTrial), findsNothing);
  });

  testWidgets('no store: says subscriptions are unavailable instead of failing', (tester) async {
    store.available = false;
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pump(tester, locale: const Locale('en'));
    expect(find.text(l10n.purchasesUnavailable), findsOneWidget);
    expect(find.text(l10n.startFreeTrial), findsNothing);
  });
}
