import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/subscription_category.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscriptions_state.dart';
import 'package:sakk/features/subscriptions/presentation/widgets/subscriptions_analytics_card.dart';
import 'package:sakk/l10n/app_localizations.dart';

UserSubscription sub(
  String id,
  double price,
  SubscriptionCategory category, {
  String currency = 'EGP',
  BillingCycle cycle = BillingCycle.monthly,
}) => UserSubscription(
  id: id,
  customName: id,
  category: category,
  price: price,
  currency: currency,
  billingCycle: cycle,
  nextRenewalDate: DateTime(2026, 11, 1),
);

Widget app(SubscriptionsState state, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SubscriptionsAnalyticsCard(state: state, onTap: () {}),
        ),
      ),
    );

void main() {
  final state = SubscriptionsState(
    hasLoadedOnce: true,
    subscriptions: [
      sub('Netflix', 240, SubscriptionCategory.streaming),
      sub(
        'Shahid',
        1200,
        SubscriptionCategory.streaming,
        cycle: BillingCycle.yearly,
      ), // 100 / month
      sub('Spotify', 60, SubscriptionCategory.music),
      sub('ChatGPT', 20, SubscriptionCategory.ai, currency: 'USD'),
    ],
  );

  testWidgets('monthly and yearly totals per currency, breakdown by category', (
    tester,
  ) async {
    await tester.pumpWidget(app(state));
    expect(find.text('400 EGP'), findsOneWidget); // 240 + 100 + 60
    expect(find.text('4,800 EGP'), findsOneWidget);

    expect(find.text('Streaming'), findsOneWidget);
    expect(find.text('340 EGP'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    expect(find.text('AI'), findsNothing); // USD only: not in the EGP breakdown

    // The switch shows USD on its own, never added to EGP.
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();
    expect(find.text('20 USD'), findsWidgets);
    expect(find.text('240 USD'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Streaming'), findsNothing);
  });

  testWidgets('Arabic digits, no overflow', (tester) async {
    await tester.pumpWidget(app(state, locale: const Locale('ar')));
    expect(find.text('٤٠٠ ج.م'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty', (tester) async {
    await tester.pumpWidget(app(const SubscriptionsState(hasLoadedOnce: true)));
    expect(find.textContaining('No subscriptions yet'), findsOneWidget);
  });
}
