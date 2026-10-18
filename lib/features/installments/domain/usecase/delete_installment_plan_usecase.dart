import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../installment_repo/installment_repo.dart';

abstract class DeleteInstallmentPlanUseCase {
  Future<Either<Failure, void>> call(String id);
}

class DeleteInstallmentPlanUseCaseImpl implements DeleteInstallmentPlanUseCase {
  final InstallmentRepo _repository;
  DeleteInstallmentPlanUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return _repository.deletePlan(id);
  }
}
