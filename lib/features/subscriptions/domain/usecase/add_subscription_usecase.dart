import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/billing_cycle.dart';
import '../entities/subscription_category.dart';
import '../entities/user_subscription.dart';
import '../subscription_repo/subscription_repo.dart';

abstract class AddSubscriptionUseCase {
  Future<Either<Failure, UserSubscription>> call({
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  });
}

class AddSubscriptionUseCaseImpl implements AddSubscriptionUseCase {
  final SubscriptionRepo _repository;
  AddSubscriptionUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, UserSubscription>> call({
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) {
    return _repository.addSubscription(
      catalogId: catalogId,
      customName: customName,
      planName: planName,
      category: category,
      price: price,
      currency: currency,
      billingCycle: billingCycle,
      nextRenewalDate: nextRenewalDate,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }
}
