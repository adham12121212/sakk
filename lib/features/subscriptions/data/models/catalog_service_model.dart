import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/catalog_service.dart';
import '../../domain/entities/subscription_category.dart';

class CatalogServiceModel extends CatalogService {
  const CatalogServiceModel({
    required super.id,
    required super.name,
    super.category,
    super.domain,
    super.logoUrl,
    super.plans,
    super.isActive,
  });

  factory CatalogServiceModel.fromJson(Map<String, dynamic> json) {
    return CatalogServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: SubscriptionCategoryX.fromName(json['category'] as String?),
      domain: json['domain'] as String?,
      logoUrl: json['logo_url'] as String?,
      plans: [
        for (final p
            in (json['plans'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          CatalogPlan(
            name: p['name'] as String,
            price: (p['price'] as num).toDouble(),
            currency: p['currency'] as String? ?? 'EGP',
            billingCycle: BillingCycleX.fromName(p['billing_cycle'] as String?),
          ),
      ],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Full row for the offline cache; round-trips through [CatalogServiceModel.fromJson].
  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'domain': domain,
    'logo_url': logoUrl,
    'is_active': isActive,
    'plans': [
      for (final p in plans)
        {
          'name': p.name,
          'price': p.price,
          'currency': p.currency,
          'billing_cycle': p.billingCycle.name,
        },
    ],
  };
}
