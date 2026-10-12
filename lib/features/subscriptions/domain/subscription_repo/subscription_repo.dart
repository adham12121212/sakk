import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/billing_cycle.dart';
import '../entities/catalog_service.dart';
import '../entities/subscription_category.dart';
import '../entities/user_subscription.dart';

abstract class SubscriptionRepo {
  /// Active services users can pick from, sorted by name.
  Future<Either<Failure, List<CatalogService>>> getCatalog();

  /// The signed-in user's subscriptions, nearest renewal first.
  Future<Either<Failure, List<UserSubscription>>> getSubscriptions();

  Future<Either<Failure, UserSubscription>> addSubscription({
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

  Future<Either<Failure, UserSubscription>> updateSubscription({
    required String id,
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

  Future<Either<Failure, void>> deleteSubscription(String id);

  /// Removes subscriptions and the catalog saved on this device for offline use.
  Future<void> clearCachedSubscriptions();
}
