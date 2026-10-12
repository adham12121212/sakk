import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/catalog_service.dart';
import 'package:sakk/features/subscriptions/domain/entities/subscription_category.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/domain/usecase/add_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/domain/usecase/delete_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/domain/usecase/get_subscriptions_usecase.dart';
import 'package:sakk/features/subscriptions/domain/usecase/update_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscription_form_cubit.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:sakk/features/subscriptions/presentation/views/subscription_form_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _NoGet implements GetSubscriptionsUseCase {
  @override
  Future<Either<Failure, List<UserSubscription>>> call() async => const Right([]);
}

/// Captures what the form sends.
class CaptureAdd implements AddSubscriptionUseCase {
  Map<String, Object?>? sent;
  @override
  Future<Either<Failure, UserSubscription>> call({
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) async {
    sent = {
      'catalogId': catalogId,
      'customName': customName,
      'planName': planName,
      'category': category,
      'price': price,
      'currency': currency,
      'billingCycle': billingCycle,
    };
    return Right(UserSubscription(
      id: 'new',
      catalogId: catalogId,
      customName: customName,
      price: price,
      billingCycle: billingCycle,
      nextRenewalDate: nextRenewalDate,
    ));
  }
}

class _NoUpdate implements UpdateSubscriptionUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoDelete implements DeleteSubscriptionUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget app(SubscriptionFormArgs args, CaptureAdd add, {Locale locale = const Locale('en')}) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // A first page so the form has something to pop back to.
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
                  builder: (_) => BlocProvider(
                    create: (_) => SubscriptionFormCubit(add, _NoUpdate(), _NoDelete(), SubscriptionsCubit(_NoGet())),
                    child: SubscriptionFormView(args: args),
                  ),
                )),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> tapSave(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Add subscription');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('custom: needs a name and a price, then saves and closes', (tester) async {
    final add = CaptureAdd();
    await tester.pumpWidget(app(const SubscriptionFormArgs.custom(), add));
    await open(tester);

    await tapSave(tester);
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter the price'), findsOneWidget);
    expect(add.sent, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  Gym  ');
    await tester.enterText(fields.at(2), '٥٠٠'); // Arabic-Indic digits are accepted
    await tester.ensureVisible(find.text('Yearly'));
    await tester.tap(find.text('Yearly'));
    await tapSave(tester);

    expect(add.sent, {
      'catalogId': null,
      'customName': 'Gym',
      'planName': null,
      'category': SubscriptionCategory.other,
      'price': 500.0,
      'currency': 'EGP',
      'billingCycle': BillingCycle.yearly,
    });
    expect(find.text('open'), findsOneWidget); // popped back
  });

  testWidgets('from the catalog: shows the service and pre-fills the plan', (tester) async {
    final add = CaptureAdd();
    const plan = CatalogPlan(name: 'Plus', price: 20, currency: 'USD', billingCycle: BillingCycle.monthly);
    const service = CatalogService(
      id: 'c1',
      name: 'ChatGPT',
      category: SubscriptionCategory.ai,
      plans: [plan],
    );
    await tester.pumpWidget(app(const SubscriptionFormArgs.fromCatalog(service, plan), add));
    await open(tester);

    expect(find.text('ChatGPT'), findsOneWidget);
    expect(find.text('Name'), findsNothing); // no name field for catalog services
    await tapSave(tester);

    expect(add.sent, {
      'catalogId': 'c1',
      'customName': null,
      'planName': 'Plus',
      'category': SubscriptionCategory.ai,
      'price': 20.0,
      'currency': 'USD',
      'billingCycle': BillingCycle.monthly,
    });
  });

  testWidgets('lays out in Arabic without overflow', (tester) async {
    await tester.pumpWidget(app(const SubscriptionFormArgs.custom(), CaptureAdd(), locale: const Locale('ar')));
    await open(tester);
    expect(find.text('إضافة اشتراك'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
