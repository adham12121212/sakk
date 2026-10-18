import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/features/installments/domain/entities/installment_payment.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan_draft.dart';
import 'package:sakk/features/installments/domain/entities/scheduled_payment.dart';
import 'package:sakk/features/installments/domain/installment_repo/installment_repo.dart';
import 'package:sakk/features/installments/domain/usecase/add_installment_plan_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/delete_installment_plan_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/get_installment_plans_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/set_payment_paid_usecase.dart';
import 'package:sakk/features/installments/domain/usecase/update_installment_plan_usecase.dart';
import 'package:sakk/features/installments/presentation/cubit/installment_form_cubit.dart';
import 'package:sakk/features/installments/presentation/cubit/installments_cubit.dart';

import 'installment_fixtures.dart';

/// Records what the use cases asked for and answers from [plans].
class _FakeRepo implements InstallmentRepo {
  List<InstallmentPlan> plans = [];
  Failure? failWith;
  String? savedId;
  List<ScheduledPayment>? savedUnpaid;
  DateTime? lastPaidAt;

  @override
  Future<Either<Failure, List<InstallmentPlan>>> getPlans() async => failWith != null ? Left(failWith!) : Right(plans);

  @override
  Future<Either<Failure, InstallmentPlan>> savePlan({
    String? id,
    required InstallmentPlanDraft draft,
    required List<ScheduledPayment> unpaid,
  }) async {
    if (failWith != null) return Left(failWith!);
    savedId = id;
    savedUnpaid = unpaid;
    return Right(InstallmentPlan(id: id ?? 'new', title: draft.title, terms: draft.terms));
  }

  @override
  Future<Either<Failure, void>> deletePlan(String id) async => failWith != null ? Left(failWith!) : const Right(null);

  @override
  Future<Either<Failure, InstallmentPayment>> setPaymentPaid(String paymentId, {DateTime? paidAt}) async {
    if (failWith != null) return Left(failWith!);
    lastPaidAt = paidAt;
    final payment = plans.expand((p) => p.payments).firstWhere((p) => p.id == paymentId);
    return Right(payment.withPaidAt(paidAt));
  }

  @override
  Future<void> clearCachedInstallments() async {}
}

void main() {
  late _FakeRepo repo;
  late InstallmentsCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    cubit = InstallmentsCubit(GetInstallmentPlansUseCaseImpl(repo), SetPaymentPaidUseCaseImpl(repo));
  });
  tearDown(() => cubit.close());

  group('InstallmentsCubit', () {
    test('loads plans sorted by next due date, once', () async {
      repo.plans = [plan('later', t: terms(start: DateTime(2027, 3, 1))), plan('sooner')];
      await cubit.loadIfNeeded();
      expect(cubit.state.plans.map((p) => p.id), ['sooner', 'later']);
      expect(cubit.state.hasLoadedOnce, isTrue);
      repo.plans = [];
      await cubit.loadIfNeeded();
      expect(cubit.state.plans, hasLength(2));
    });

    test('keeps the list and reports the error when a refresh fails', () async {
      repo.plans = [plan('a')];
      await cubit.refresh();
      repo.failWith = const ServerFailure('boom');
      await cubit.refresh();
      expect(cubit.state.plans, hasLength(1));
      expect(cubit.state.error, 'boom');
    });

    test('marks a payment paid and unpaid again', () async {
      repo.plans = [plan('a', t: terms(count: 2, total: 2000), paid: {0})];
      await cubit.refresh();
      expect(await cubit.setPaymentPaid('a', 'a-p1', paid: true), isNull);
      expect(repo.lastPaidAt, isNotNull);
      expect(cubit.state.planById('a')!.isCompleted, isTrue);
      expect(cubit.state.updatingPaymentIds, isEmpty);

      expect(await cubit.setPaymentPaid('a', 'a-p1', paid: false), isNull);
      expect(repo.lastPaidAt, isNull);
      expect(cubit.state.planById('a')!.status, InstallmentPlanStatus.active);
    });

    test('a failed mark-as-paid changes nothing and returns the message', () async {
      repo.plans = [plan('a')];
      await cubit.refresh();
      repo.failWith = const NetworkFailure(NetworkFailure.noConnectionMessage);
      expect(await cubit.setPaymentPaid('a', 'a-p0', paid: true), NetworkFailure.noConnectionMessage);
      expect(cubit.state.planById('a')!.paidCount, 0);
      expect(cubit.state.updatingPaymentIds, isEmpty);
    });

    test('reset forgets the account', () async {
      repo.plans = [plan('a')];
      await cubit.refresh();
      cubit.reset();
      expect(cubit.state.plans, isEmpty);
      expect(cubit.state.hasLoadedOnce, isFalse);
    });

    test('counts overdue installments on active plans', () async {
      repo.plans = [plan('a', t: terms(start: DateTime(2026, 9, 1))), plan('c', cancelled: true, t: terms(start: DateTime(2026, 9, 1)))];
      await cubit.refresh();
      expect(cubit.state.overdueCount(DateTime(2026, 10, 18)), 2);
    });
  });

  group('InstallmentFormCubit', () {
    late InstallmentFormCubit form;
    setUp(() => form = InstallmentFormCubit(
          AddInstallmentPlanUseCaseImpl(repo),
          UpdateInstallmentPlanUseCaseImpl(repo),
          DeleteInstallmentPlanUseCaseImpl(repo),
          cubit,
        ));
    tearDown(() => form.close());

    test('adding sends the whole schedule and puts the plan in the list', () async {
      await form.save(InstallmentPlanDraft(title: 'TV', terms: terms(count: 3, total: 3000)));
      expect(form.state, isA<InstallmentFormSaved>());
      expect(repo.savedId, isNull);
      expect(repo.savedUnpaid, hasLength(3));
      expect(cubit.state.planById('new'), isNotNull);
    });

    test('editing sends only the unpaid installments', () async {
      final current = plan('a', t: terms(count: 4, total: 4000), paid: {0});
      await form.save(current.toDraft(), current: current);
      expect(repo.savedId, 'a');
      expect(repo.savedUnpaid, hasLength(3));
    });

    test('editing below the installments paid is refused without saving', () async {
      final current = plan('a', t: terms(count: 4, total: 4000), paid: {0, 1, 2});
      final draft = InstallmentPlanDraft(title: 'a', terms: terms(count: 2, total: 4000));
      await form.save(draft, current: current);
      final state = form.state;
      expect(state, isA<InstallmentFormFailure>());
      expect((state as InstallmentFormFailure).message, UpdateInstallmentPlanUseCase.tooFewInstallments);
      expect(repo.savedId, isNull);
    });

    test('deleting removes the plan from the list', () async {
      repo.plans = [plan('a')];
      await cubit.refresh();
      await form.delete('a');
      expect(form.state, isA<InstallmentFormDeleted>());
      expect(cubit.state.plans, isEmpty);
    });
  });
}
