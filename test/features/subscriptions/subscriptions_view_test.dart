import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/domain/usecase/get_subscriptions_usecase.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:sakk/features/subscriptions/presentation/views/subscriptions_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _FakeGet implements GetSubscriptionsUseCase {
  _FakeGet(this.result);
  final Either<Failure, List<UserSubscription>> result;
  @override
  Future<Either<Failure, List<UserSubscription>>> call() async => result;
}

Widget app(SubscriptionsCubit cubit, {Locale locale = const Locale('en'), bool dark = false}) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: cubit, child: const SubscriptionsView()),
      ),
    );

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // No domains: the letter avatar, so the test makes no network calls.
  final subs = [
    UserSubscription(
      id: '1',
      customName: 'Netflix',
      planName: 'Premium',
      price: 240,
      billingCycle: BillingCycle.monthly,
      nextRenewalDate: today.add(const Duration(days: 2)),
    ),
    UserSubscription(
      id: '2',
      customName: 'Microsoft 365',
      price: 1200,
      billingCycle: BillingCycle.yearly,
      nextRenewalDate: today.add(const Duration(days: 40)),
    ),
    UserSubscription(
      id: '3',
      customName: 'ChatGPT',
      price: 20,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      nextRenewalDate: today.add(const Duration(days: 9)),
    ),
  ];

  testWidgets('shows the monthly total and the list, nearest renewal first', (tester) async {
    await tester.pumpWidget(app(SubscriptionsCubit(_FakeGet(Right(subs)))));
    await tester.pumpAndSettle();

    expect(find.text('340 EGP'), findsOneWidget); // 240 + 1200 / 12
    expect(find.text('+ 20 USD'), findsOneWidget);
    expect(find.text('4,080 EGP a year'), findsOneWidget);
    expect(find.text('3 subscriptions'), findsOneWidget);

    final netflix = tester.getTopLeft(find.text('Netflix')).dy;
    final chatGpt = tester.getTopLeft(find.text('ChatGPT')).dy;
    final office = tester.getTopLeft(find.text('Microsoft 365')).dy;
    expect(netflix < chatGpt && chatGpt < office, isTrue);
    expect(find.textContaining('Renews in 2 days'), findsOneWidget);
    expect(find.text('1,200 EGP / year'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget); // the floating button
  });

  testWidgets('Arabic, dark mode: right-to-left with Arabic digits and no overflow', (tester) async {
    await tester.pumpWidget(app(SubscriptionsCubit(_FakeGet(Right(subs))), locale: const Locale('ar'), dark: true));
    await tester.pumpAndSettle();

    expect(find.text('٣٤٠ ج.م'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('Netflix'))), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty list invites to add the first subscription', (tester) async {
    await tester.pumpWidget(app(SubscriptionsCubit(_FakeGet(const Right([])))));
    await tester.pumpAndSettle();
    expect(find.text('No subscriptions yet'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget); // the empty view's button, no FAB
  });

  testWidgets('a failed first load shows the offline error', (tester) async {
    await tester.pumpWidget(
      app(SubscriptionsCubit(_FakeGet(const Left(NetworkFailure(NetworkFailure.noConnectionMessage))))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });
}
