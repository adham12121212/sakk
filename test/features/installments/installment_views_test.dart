import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/installments/domain/entities/installment_payment.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan_draft.dart';
import 'package:sakk/features/installments/domain/entities/scanned_installment.dart';
import 'package:sakk/features/installments/domain/entities/scheduled_payment.dart';
import 'package:sakk/features/installments/domain/installment_repo/installment_repo.dart';
import 'package:sakk/features/installments/domain/usecase/add_installment_plan_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/delete_installment_plan_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/extract_installment_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/get_installment_plans_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/set_payment_paid_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/update_installment_plan_usecase.dart';
import 'package:sakk/features/installments/presentation/cubit/installment_form_cubit.dart';
import 'package:sakk/features/installments/presentation/cubit/installment_smart_add_cubit.dart';
import 'package:sakk/features/installments/presentation/cubit/installments_cubit.dart';
import 'package:sakk/features/installments/presentation/views/installment_details_view.dart';
import 'package:sakk/features/installments/presentation/views/installment_form_view.dart';
import 'package:sakk/features/installments/presentation/views/installments_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

import 'installment_fixtures.dart';

class _Repo implements InstallmentRepo {
  _Repo(this.plans);
  List<InstallmentPlan> plans;
  InstallmentPlanDraft? savedDraft;
  List<ScheduledPayment>? savedUnpaid;
  final paidCalls = <String, DateTime?>{};

  @override
  Future<Either<Failure, List<InstallmentPlan>>> getPlans() async =>
      Right(plans);

  @override
  Future<Either<Failure, InstallmentPlan>> savePlan({
    String? id,
    required InstallmentPlanDraft draft,
    required List<ScheduledPayment> unpaid,
  }) async {
    savedDraft = draft;
    savedUnpaid = unpaid;
    return Right(
      InstallmentPlan(id: id ?? 'new', title: draft.title, terms: draft.terms),
    );
  }

  @override
  Future<Either<Failure, void>> deletePlan(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, InstallmentPayment>> setPaymentPaid(
    String paymentId, {
    DateTime? paidAt,
  }) async {
    paidCalls[paymentId] = paidAt;
    final p = plans
        .expand((p) => p.payments)
        .firstWhere((p) => p.id == paymentId);
    return Right(p.withPaidAt(paidAt));
  }

  @override
  Future<void> clearCachedInstallments() async {}

  ScannedInstallment scan = const ScannedInstallment();
  @override
  Future<Either<Failure, ScannedInstallment>> extractInstallment({
    String? imagePath,
    String? pdfText,
    String? text,
  }) async => Right(scan);
}

Widget app(
  Widget home, {
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
    home: home,
  ),
);

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late _Repo repo;
  late InstallmentsCubit cubit;
  InstallmentFormCubit formCubit() => InstallmentFormCubit(
    AddInstallmentPlanUseCaseImpl(repo),
    UpdateInstallmentPlanUseCaseImpl(repo),
    DeleteInstallmentPlanUseCaseImpl(repo),
    cubit,
  );

  // TV: 12 x 1,000 from 2 months ago, first one paid, second overdue.
  // Car: 6 x 5,000 starting in 10 days.
  List<InstallmentPlan> plans() => [
    plan(
      'car',
      t: terms(
        total: 30000,
        count: 6,
        start: DateTime(today.year, today.month, today.day + 10),
      ),
    ),
    plan(
      'tv',
      t: terms(
        total: 12000,
        count: 12,
        start: DateTime(today.year, today.month - 1, today.day - 5),
      ),
      paid: {0},
    ),
  ];

  void setUpCubit(List<InstallmentPlan> list) {
    repo = _Repo(list);
    cubit = InstallmentsCubit(
      GetInstallmentPlansUseCaseImpl(repo),
      SetPaymentPaidUseCaseImpl(repo),
    );
  }

  group('InstallmentsView', () {
    testWidgets('shows what is left and the plans, overdue first', (
      tester,
    ) async {
      setUpCubit(plans());
      await tester.pumpWidget(
        app(BlocProvider.value(value: cubit, child: const InstallmentsView())),
      );
      await tester.pumpAndSettle();

      expect(find.text('41,000 EGP'), findsOneWidget); // 11 x 1,000 + 6 x 5,000
      expect(find.textContaining('overdue'), findsWidgets);
      final tv = tester.getTopLeft(find.text('tv'));
      final car = tester.getTopLeft(find.text('car'));
      expect(tv.dy, lessThan(car.dy));
      expect(find.text('1 of 12 paid'), findsOneWidget);
      expect(find.text('Due in 10 days'), findsOneWidget);
    });

    testWidgets('invites to add the first plan', (tester) async {
      setUpCubit([]);
      await tester.pumpWidget(
        app(BlocProvider.value(value: cubit, child: const InstallmentsView())),
      );
      await tester.pumpAndSettle();
      expect(find.text('No installments yet'), findsOneWidget);
      expect(find.text('Add installment'), findsOneWidget);
    });

    testWidgets('lays out in Arabic and dark mode', (tester) async {
      setUpCubit(plans());
      await tester.pumpWidget(
        app(
          BlocProvider.value(value: cubit, child: const InstallmentsView()),
          locale: const Locale('ar'),
          dark: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('الأقساط'), findsOneWidget);
      expect(find.textContaining('مستحق خلال ١٠'), findsOneWidget);
    });
  });

  group('InstallmentDetailsView', () {
    Widget details(String id, {Locale locale = const Locale('en')}) => app(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider(create: (_) => formCubit()),
        ],
        child: InstallmentDetailsView(planId: id),
      ),
      locale: locale,
    );

    testWidgets(
      'marks the next installment paid, and a paid one unpaid again',
      (tester) async {
        setUpCubit(plans());
        await cubit.refresh();
        await tester.pumpWidget(details('tv'));
        await tester.pumpAndSettle();

        expect(
          find.text('1 installment is overdue (1,000 EGP)'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Mark as paid'));
        await tester.pumpAndSettle();
        expect(repo.paidCalls['tv-p1'], isNotNull);
        expect(find.text('2 of 12 paid'), findsOneWidget);
        expect(find.textContaining('overdue ('), findsNothing);

        // Let the "Marked as paid" snackbar go so it doesn't cover the list.
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        final unpaid = find.byTooltip('Mark as unpaid').first;
        await tester.ensureVisible(unpaid);
        await tester.pumpAndSettle();
        await tester.tap(unpaid);
        await tester.pumpAndSettle();
        expect(find.text('Mark as unpaid?'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Mark as unpaid'));
        await tester.pumpAndSettle();
        expect(
          repo.paidCalls.containsKey('tv-p0') &&
              repo.paidCalls['tv-p0'] == null,
          isTrue,
        );
        // The summary has scrolled out of the list by now.
        expect(cubit.state.planById('tv')!.paidCount, 1);
      },
    );

    testWidgets('lays out in Arabic', (tester) async {
      setUpCubit(plans());
      await cubit.refresh();
      await tester.pumpWidget(details('tv', locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('جدول الأقساط'), 200);
      expect(find.text('جدول الأقساط'), findsOneWidget);
    });
  });

  group('InstallmentFormView', () {
    Widget form(InstallmentFormArgs args) => app(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => formCubit()),
          BlocProvider(
            create: (_) =>
                InstallmentSmartAddCubit(ExtractInstallmentUseCaseImpl(repo)),
          ),
        ],
        child: InstallmentFormView(args: args, products: const []),
      ),
    );

    String fieldText(WidgetTester tester, String label) => tester
        .widget<TextFormField>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == label,
            ),
            matching: find.byType(TextFormField),
          ),
        )
        .controller!
        .text;

    Future<void> enter(WidgetTester tester, String label, String text) async {
      final field = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label,
        ),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
      await tester.pump();
    }

    testWidgets('splits the price and previews the schedule as you type', (
      tester,
    ) async {
      setUpCubit([]);
      await tester.pumpWidget(form(const InstallmentFormArgs.add()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Something else'));
      await tester.pump();

      await enter(tester, 'What did you buy?', 'Laptop');
      await enter(tester, 'Total Price', '13000');
      await enter(tester, 'Down payment (optional)', '1000');
      await enter(tester, 'Number of installments', '12');
      expect(
        fieldText(tester, 'Monthly installment'),
        '1000',
      ); // the even split
      expect(
        find.textContaining('12 installments · 13,000 EGP in total'),
        findsOneWidget,
      );

      await enter(tester, 'Monthly installment', '1100');
      expect(find.text('Your own amount.'), findsOneWidget);
      expect(
        find.textContaining('12 installments · 14,200 EGP in total'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Add installment'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add installment'));
      await tester.pumpAndSettle();
      expect(repo.savedDraft!.title, 'Laptop');
      expect(repo.savedDraft!.productId, isNull);
      expect(repo.savedDraft!.terms.installmentAmount, 1100);
      expect(repo.savedUnpaid, hasLength(12));
    });

    testWidgets(
      'smart add fills the form for review; nothing is saved until the user saves',
      (tester) async {
        setUpCubit([]);
        repo.scan = ScannedInstallment(
          title: 'iPhone 16',
          provider: 'Valu',
          totalPrice: 60000,
          downPayment: 12000,
          installmentAmount: 4300,
          installmentsCount: 12,
          firstDueDate: DateTime(2026, 11, 30),
          dueDayOfMonth: 31,
          confidence: 0.9,
        );
        await tester.pumpWidget(form(const InstallmentFormArgs.add()));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(InstallmentFormView));
        await BlocProvider.of<InstallmentSmartAddCubit>(
          context,
        ).read(text: 'contract');
        await tester.pumpAndSettle();

        expect(fieldText(tester, 'What did you buy?'), 'iPhone 16');
        expect(fieldText(tester, 'Provider (optional)'), 'Valu');
        expect(fieldText(tester, 'Total Price'), '60000');
        expect(fieldText(tester, 'Monthly installment'), '4300');
        expect(
          find.text('Your own amount.'),
          findsOneWidget,
        ); // 4300 isn't the even split (4000)
        expect(
          find.textContaining('Check every field before saving'),
          findsOneWidget,
        );
        expect(
          find.textContaining('12 installments · 63,600 EGP in total'),
          findsOneWidget,
        );
        expect(repo.savedDraft, isNull);

        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Add installment'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Add installment'));
        await tester.pumpAndSettle();
        expect(repo.savedDraft!.provider, 'Valu');
        expect(repo.savedDraft!.terms.dueDayOfMonth, 31);
        expect(repo.savedUnpaid!.first.dueDate, DateTime(2026, 11, 30));
        expect(repo.savedUnpaid![3].dueDate, DateTime(2027, 2, 28));
      },
    );

    testWidgets('editing keeps paid installments and refuses fewer than paid', (
      tester,
    ) async {
      setUpCubit([]);
      final current = plan(
        'tv',
        t: terms(total: 12000, count: 12),
        paid: {0, 1, 2},
      );
      await tester.pumpWidget(form(InstallmentFormArgs.edit(current)));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('3 installments are already paid'),
        findsOneWidget,
      );

      await enter(tester, 'Number of installments', '2');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save Changes'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('At least 3'), findsOneWidget);
      expect(repo.savedDraft, isNull);

      await enter(tester, 'Number of installments', '12');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save Changes'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
      await tester.pumpAndSettle();
      expect(repo.savedUnpaid, hasLength(9));
    });
  });
}
