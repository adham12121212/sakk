import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/theme/app_icons.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/home/presentation/widgets/home_sections.dart';
import 'package:sakk/core/widgets/warranty_summary_card.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan.dart';
import 'package:sakk/features/installments/domain/usecase/get_installment_plans_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/set_payment_paid_usecase.dart';
import 'package:sakk/features/installments/presentation/cubit/installments_cubit.dart';
import 'package:sakk/features/papers/domain/entities/paper.dart';
import 'package:sakk/features/papers/domain/usecase/get_papers_usecase.dart';
import 'package:sakk/features/papers/presentation/cubit/papers_cubit.dart';
import 'package:sakk/features/papers/presentation/views/paper_details_view.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/domain/usecase/get_subscriptions_usecase.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _Papers implements GetPapersUseCase {
  _Papers(this.papers);
  final List<Paper> papers;
  @override
  Future<Either<Failure, List<Paper>>> call() async => Right(papers);
}

class _NoSubscriptions implements GetSubscriptionsUseCase {
  @override
  Future<Either<Failure, List<UserSubscription>>> call() async =>
      const Right([]);
}

class _NoPlans implements GetInstallmentPlansUseCase {
  @override
  Future<Either<Failure, List<InstallmentPlan>>> call() async =>
      const Right([]);
}

class _NoPaid implements SetPaymentPaidUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

DateTime inDays(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

Widget app(Widget child, {Locale locale = const Locale('en')}) =>
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  final passport = Paper(
    id: 'p',
    kind: PaperKind.passport,
    title: "Mona's passport",
    number: 'A1234567',
    expiryDate: inDays(12),
    notes: 'In the drawer',
  );

  testWidgets('details: status, number, countdown, notes and photo hint', (
    tester,
  ) async {
    final papers = PapersCubit(_Papers([passport]));
    await papers.refresh();
    await tester.pumpWidget(
      app(
        BlocProvider.value(
          value: papers,
          child: PaperDetailsView(paper: passport),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Mona's passport"), findsWidgets);
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.text('A1234567'), findsOneWidget);
    expect(find.text('Expires in 12 days'), findsOneWidget);
    expect(find.text('In the drawer'), findsOneWidget);
    expect(find.byTooltip('Copy number'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(
      find.text('No photos. Tap Edit to add the front and back.'),
      findsOneWidget,
    );
  });

  testWidgets('details follow the shared list after an edit', (tester) async {
    final papers = PapersCubit(_Papers([passport]));
    await papers.refresh();
    await tester.pumpWidget(
      app(
        BlocProvider.value(
          value: papers,
          child: PaperDetailsView(paper: passport),
        ),
      ),
    );
    papers.upsert(
      Paper(id: 'p', kind: PaperKind.passport, expiryDate: inDays(-3)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('A1234567'), findsNothing);
  });

  testWidgets('summary card: total and a count per status', (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: WarrantySummaryCard(active: 9, expiring: 2, expired: 1),
        ),
      ),
    );
    expect(find.text('12'), findsOneWidget);
    expect(find.text('9 Active', findRichText: true), findsOneWidget);
    expect(find.text('2 Expiring', findRichText: true), findsOneWidget);
    expect(find.text('1 Expired', findRichText: true), findsOneWidget);
    // The split bar's parts are drawn (they were 0 tall once).
    final parts = find.descendant(
      of: find.byType(WarrantySummaryCard),
      matching: find.byType(ColoredBox),
    );
    expect(parts, findsNWidgets(3));
    for (final part in parts.evaluate()) {
      expect(tester.getSize(find.byWidget(part.widget)).height, 8);
    }

    // Nothing yet, in Arabic on a small phone.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: WarrantySummaryCard(active: 0, expiring: 0, expired: 0),
        ),
        locale: const Locale('ar'),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('money section and the papers row: empty, then with data', (
    tester,
  ) async {
    final subscriptions = SubscriptionsCubit(_NoSubscriptions());
    final installments = InstallmentsCubit(_NoPlans(), _NoPaid());
    final empty = PapersCubit(_Papers(const []));
    await Future.wait([
      subscriptions.refresh(),
      installments.refresh(),
      empty.refresh(),
    ]);
    Widget sections(PapersCubit papers, {Locale locale = const Locale('en')}) =>
        app(
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                HomeMoneySection(
                  subscriptions: subscriptions,
                  installments: installments,
                  onSubscriptionsTap: () {},
                  onInstallmentsTap: () {},
                ),
                HomePapersSection(papers: papers, onOpen: () {}),
              ],
            ),
          ),
          locale: locale,
        );

    await tester.pumpWidget(sections(empty));
    expect(find.text('Money this month'), findsOneWidget);
    expect(find.text('Track Netflix, Spotify and more'), findsOneWidget);
    expect(find.text('My papers'), findsOneWidget); // its own heading
    expect(find.text('Add paper'), findsOneWidget);
    expect(find.text('Your ID, passport and licences'), findsOneWidget);

    final papers = PapersCubit(
      _Papers([
        passport,
        Paper(id: 'id', kind: PaperKind.nationalId, expiryDate: inDays(400)),
        Paper(
          id: 'old',
          kind: PaperKind.drivingLicence,
          expiryDate: inDays(900),
        ),
      ]),
    );
    await papers.refresh();
    var opens = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: HomePapersSection(papers: papers, onOpen: () => opens++),
        ),
      ),
    );
    // One row: how many, and how many need renewing; no paper is listed.
    expect(find.text('3 papers'), findsOneWidget);
    expect(find.text('1 needs renewing'), findsOneWidget);
    expect(find.text("Mona's passport"), findsNothing);
    expect(find.byIcon(AppIcons.add), findsNothing);
    await tester.tap(find.text('3 papers'));
    expect(opens, 1);

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(sections(papers, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
