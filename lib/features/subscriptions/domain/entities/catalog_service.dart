import 'package:equatable/equatable.dart';

import 'billing_cycle.dart';
import 'subscription_category.dart';

/// A known service from the shared catalog (Netflix, Spotify...).
class CatalogService extends Equatable {
  final String id;
  final String name;
  final SubscriptionCategory category;

  /// Used for the logo when [logoUrl] is null.
  final String? domain;
  final String? logoUrl;
  final List<CatalogPlan> plans;
  final bool isActive;

  const CatalogService({
    required this.id,
    required this.name,
    this.category = SubscriptionCategory.other,
    this.domain,
    this.logoUrl,
    this.plans = const [],
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    domain,
    logoUrl,
    plans,
    isActive,
  ];
}

class CatalogPlan extends Equatable {
  final String name;
  final double price;
  final String currency;
  final BillingCycle billingCycle;

  const CatalogPlan({
    required this.name,
    required this.price,
    required this.currency,
    required this.billingCycle,
  });

  @override
  List<Object?> get props => [name, price, currency, billingCycle];
}
