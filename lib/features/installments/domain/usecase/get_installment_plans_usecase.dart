import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/installment_plan.dart';
import '../installment_repo/installment_repo.dart';

abstract class GetInstallmentPlansUseCase {
  Future<Either<Failure, List<InstallmentPlan>>> call();
}

class GetInstallmentPlansUseCaseImpl implements GetInstallmentPlansUseCase {
  final InstallmentRepo _repository;
  GetInstallmentPlansUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, List<InstallmentPlan>>> call() {
    return _repository.getPlans();
  }
}
