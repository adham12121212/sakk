import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/exceptions.dart';
import 'package:sakk/core/error/user_facing_error.dart';
import 'package:sakk/core/service/receipt_ai_client.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/installments/data/installment_data_source/installment_data_source.dart';
import 'package:sakk/features/installments/domain/installment_totals.dart';
import 'package:sakk/features/installments/presentation/cubit/installments_state.dart';
import 'package:sakk/features/installments/presentation/widgets/installments_analytics_card.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:sakk/l10n/app_localizations_en.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../subscriptions/smart_add_test.dart' show FakeAi;
import 'installment_fixtures.dart';

void main() {
  group('extractInstallment', () {
    late FakeAi ai;
    late InstallmentDataSourceImpl source;
    setUp(() {
      ai = FakeAi();
      source = InstallmentDataSourceImpl(
        SupabaseClient('https://x.supabase.co', 'anon'),
        ai: ai,
      );
    });

    test(
      'sends the contract to the installment mode and reads the answer',
      () async {
        ai.answer = {
          'title': 'Fridge',
          'provider': 'Contact',
          'totalPrice': 30000,
          'downPayment': 5000,
          'installmentAmount': 2500.5,
          'installmentsCount': 10,
          'firstDueDate': '2026-12-01',
          'dueDayOfMonth': 1,
          'interestOrFees': null,
          'currency': 'EGP',
          'confidence': 0.8,
        };
        final scan = await source.extractInstallment(
          imagePath: '/tmp/page.png',
          pdfText:
              'Card 4111 1111 1111 4242, contact me at someone@example.com',
        );
        expect(ai.sentBody!['mode'], 'installment');
        expect(ai.sentBody!['imageUrl'], 'https://signed/u1/1.jpg');
        // Card numbers and emails never leave the device.
        expect(ai.sentBody!['pdfText'], isNot(contains('4111')));
        expect(ai.sentBody!['pdfText'], isNot(contains('someone@example.com')));
        expect(ai.sentBody!.containsKey('text'), isFalse);
        expect(ai.deleted, ['u1/1.jpg']); // the page isn't kept

        expect(scan.title, 'Fridge');
        expect(scan.installmentAmount, 2500.5);
        expect(scan.installmentsCount, 10);
        expect(scan.firstDueDate, DateTime(2026, 12, 1));
        expect(scan.interestOrFees, isNull);
      },
    );

    test('nothing found becomes its own message', () async {
      ai.throwOnExtract = ServerException(ReceiptAiClient.unreadable);
      await expectLater(
        source.extractInstallment(text: 'hello'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            InstallmentDataSourceImpl.unreadableInstallment,
          ),
        ),
      );
      expect(
        userFacingError(
          AppLocalizationsEn(),
          InstallmentDataSourceImpl.unreadableInstallment,
        ),
        startsWith("We couldn't find an installment plan"),
      );
    });
  });

  group('dueByMonth', () {
    test(
      'adds what falls due each month, paid or not, skipping cancelled plans',
      () {
        final a = plan(
          'a',
          t: terms(total: 3000, count: 3, start: DateTime(2026, 10, 31)),
          paid: {0},
        );
        final b = plan(
          'b',
          t: terms(total: 1000, count: 2, start: DateTime(2026, 11, 15)),
        );
        final cancelled = plan(
          'c',
          t: terms(total: 9000, count: 3, start: DateTime(2026, 11, 1)),
          cancelled: true,
        );
        final usd = plan(
          'u',
          t: terms(total: 50, count: 1, start: DateTime(2026, 11, 1)),
          currency: 'USD',
        );
        final months = dueByMonth(
          [a, b, cancelled, usd],
          from: DateTime(2026, 10, 18),
          months: 4,
        );
        expect(months.map((m) => (m.month, m.amount)), [
          (10, 1000.0),
          (11, 1500.0),
          (12, 1500.0),
          (1, 0.0),
        ]);
        expect(months.last.year, 2027);
      },
    );
  });

  group('InstallmentsAnalyticsCard', () {
    Widget card(
      InstallmentsState state, {
      Locale locale = const Locale('en'),
      bool dark = false,
    }) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: InstallmentsAnalyticsCard(
              state: state,
              onTap: () {},
              today: DateTime(2026, 10, 18),
            ),
          ),
        ),
      ),
    );

    final plans = [
      plan(
        'tv',
        t: terms(total: 6000, count: 6, start: DateTime(2026, 9, 5)),
        paid: {0},
      ), // Oct overdue
      plan(
        'car',
        t: terms(total: 12000, count: 6, start: DateTime(2026, 11, 1)),
      ),
    ];

    testWidgets(
      'shows what is left, this month, overdue, and a bar per month',
      (tester) async {
        await tester.pumpWidget(
          card(InstallmentsState(plans: plans, hasLoadedOnce: true)),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('17,000 EGP'),
          findsOneWidget,
        ); // 5 x 1,000 + 6 x 2,000
        expect(find.text('Oct · 1,000 EGP'), findsOneWidget);
        expect(find.text('1,000 EGP overdue'), findsOneWidget);

        await tester.tap(find.bySemanticsLabel('Nov: 3,000 EGP'));
        await tester.pumpAndSettle();
        expect(find.text('Nov · 3,000 EGP'), findsOneWidget);
      },
    );

    testWidgets('invites to add when there are no plans', (tester) async {
      await tester.pumpWidget(
        card(const InstallmentsState(hasLoadedOnce: true)),
      );
      expect(find.textContaining('No installments yet'), findsOneWidget);
    });

    testWidgets('lays out in Arabic and dark mode', (tester) async {
      await tester.pumpWidget(
        card(
          InstallmentsState(plans: plans, hasLoadedOnce: true),
          locale: const Locale('ar'),
          dark: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('المستحق كل شهر'), findsOneWidget);
    });
  });
}
