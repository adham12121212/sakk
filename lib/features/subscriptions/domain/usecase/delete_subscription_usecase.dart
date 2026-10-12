import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../subscription_repo/subscription_repo.dart';

abstract class DeleteSubscriptionUseCase {
  Future<Either<Failure, void>> call(String id);
}

class DeleteSubscriptionUseCaseImpl implements DeleteSubscriptionUseCase {
  final SubscriptionRepo _repository;
  DeleteSubscriptionUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteSubscription(id);
  }
}
