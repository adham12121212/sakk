import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/installment_plan.dart';
import '../entities/installment_plan_draft.dart';
import '../installment_repo/installment_repo.dart';
import '../installment_schedule.dart';

abstract class AddInstallmentPlanUseCase {
  /// Saves a new plan with every installment built from its terms.
  Future<Either<Failure, InstallmentPlan>> call(InstallmentPlanDraft draft);
}

class AddInstallmentPlanUseCaseImpl implements AddInstallmentPlanUseCase {
  final InstallmentRepo _repository;
  AddInstallmentPlanUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, InstallmentPlan>> call(InstallmentPlanDraft draft) {
    return _repository.savePlan(
      draft: draft,
      unpaid: buildSchedule(draft.terms),
    );
  }
}
