import '../subscription_repo/subscription_repo.dart';

abstract class ClearCachedSubscriptionsUseCase {
  Future<void> call();
}

class ClearCachedSubscriptionsUseCaseImpl
    implements ClearCachedSubscriptionsUseCase {
  final SubscriptionRepo _subscriptionRepo;
  ClearCachedSubscriptionsUseCaseImpl(this._subscriptionRepo);

  @override
  Future<void> call() => _subscriptionRepo.clearCachedSubscriptions();
}
