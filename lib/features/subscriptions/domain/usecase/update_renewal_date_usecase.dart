import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../subscription_repo/subscription_repo.dart';

abstract class UpdateRenewalDateUseCase {
  Future<Either<Failure, void>> call(
    String id,
    DateTime nextRenewalDate, {
    int? renewalDay,
  });
}

class UpdateRenewalDateUseCaseImpl implements UpdateRenewalDateUseCase {
  final SubscriptionRepo _repository;
  UpdateRenewalDateUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(
    String id,
    DateTime nextRenewalDate, {
    int? renewalDay,
  }) {
    return _repository.updateRenewalDate(
      id,
      nextRenewalDate,
      renewalDay: renewalDay,
    );
  }
}
