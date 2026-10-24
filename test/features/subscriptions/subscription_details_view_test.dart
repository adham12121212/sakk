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
import 'package:sakk/features/subscriptions/presentation/views/subscription_details_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _Get implements GetSubscriptionsUseCase {
  _Get(this.list);
  final List<UserSubscription> list;
  @override
  Future<Either<Failure, List<UserSubscription>>> call() async => Right(list);
}

DateTime inDays(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

Widget app(SubscriptionsCubit cubit, UserSubscription s, {Locale? locale}) =>
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale ?? const Locale('en'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: SubscriptionDetailsView(subscription: s),
        ),
      ),
    );

void main() {
  final gym = UserSubscription(
    id: 'g',
    customName: 'Gym',
    planName: 'Gold',
    price: 6000,
    billingCycle: BillingCycle.yearly,
    nextRenewalDate: inDays(3),
    paymentMethod: 'CIB card',
    notes: 'Front desk renews it',
  );

  testWidgets('shows the price, monthly equivalent, renewal and details', (
    tester,
  ) async {
    final cubit = SubscriptionsCubit(_Get([gym]));
    await cubit.refresh();
    await tester.pumpWidget(app(cubit, gym));
    await tester.pumpAndSettle();

    expect(find.text('Gym'), findsWidgets);
    expect(find.text('Renews in 3 days'), findsOneWidget);
    expect(find.text('6,000 EGP / year'), findsOneWidget);
    expect(find.text("That's 500 EGP a month"), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('CIB card'), findsOneWidget);
    expect(find.text('Front desk renews it'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
  });

  testWidgets('lays out in Arabic without overflow', (tester) async {
    final cubit = SubscriptionsCubit(_Get([gym]));
    await cubit.refresh();
    await tester.pumpWidget(app(cubit, gym, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
