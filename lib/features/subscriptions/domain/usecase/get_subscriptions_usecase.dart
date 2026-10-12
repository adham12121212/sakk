import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/user_subscription.dart';
import '../subscription_repo/subscription_repo.dart';

abstract class GetSubscriptionsUseCase {
  Future<Either<Failure, List<UserSubscription>>> call();
}

class GetSubscriptionsUseCaseImpl implements GetSubscriptionsUseCase {
  final SubscriptionRepo _repository;
  GetSubscriptionsUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, List<UserSubscription>>> call() {
    return _repository.getSubscriptions();
  }
}
