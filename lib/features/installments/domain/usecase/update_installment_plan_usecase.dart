import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/installment_plan.dart';
import '../entities/installment_plan_draft.dart';
import '../installment_repo/installment_repo.dart';
import '../installment_schedule.dart';

abstract class UpdateInstallmentPlanUseCase {
  /// Failure message when the new count is below the installments already
  /// paid.
  static const tooFewInstallments = 'too_few_installments';

  /// Saves [draft] over [current]. Paid installments are kept; the unpaid
  /// ones follow the new terms (see [unpaidScheduleForEdit]).
  Future<Either<Failure, InstallmentPlan>> call(
    InstallmentPlan current,
    InstallmentPlanDraft draft,
  );
}

class UpdateInstallmentPlanUseCaseImpl implements UpdateInstallmentPlanUseCase {
  final InstallmentRepo _repository;
  UpdateInstallmentPlanUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, InstallmentPlan>> call(
    InstallmentPlan current,
    InstallmentPlanDraft draft,
  ) async {
    if (draft.terms.installmentsCount < minimumInstallmentsCount(current)) {
      return const Left(
        ValidationFailure(UpdateInstallmentPlanUseCase.tooFewInstallments),
      );
    }
    return _repository.savePlan(
      id: current.id,
      draft: draft,
      unpaid: unpaidScheduleForEdit(current, draft.terms),
    );
  }
}
