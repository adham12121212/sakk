import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/subscription_category.dart';
import '../../domain/entities/user_subscription.dart';

class UserSubscriptionModel extends UserSubscription {
  const UserSubscriptionModel({
    required super.id,
    super.catalogId,
    super.customName,
    super.catalogName,
    super.domain,
    super.logoUrl,
    super.planName,
    super.category,
    required super.price,
    super.currency,
    required super.billingCycle,
    required super.nextRenewalDate,
    super.paymentMethod,
    super.notes,
    super.createdAt,
  });

  /// Columns to select so a row arrives with its catalog service's name and
  /// logo embedded (PostgREST follows the catalog_id foreign key).
  static const selectColumns =
      '*, subscription_catalog(name, domain, logo_url)';

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final catalog = json['subscription_catalog'] as Map<String, dynamic>?;
    return UserSubscriptionModel(
      id: json['id'] as String,
      catalogId: json['catalog_id'] as String?,
      customName: json['custom_name'] as String?,
      catalogName: catalog?['name'] as String?,
      domain: catalog?['domain'] as String?,
      logoUrl: catalog?['logo_url'] as String?,
      planName: json['plan_name'] as String?,
      category: SubscriptionCategoryX.fromName(json['category'] as String?),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      billingCycle: BillingCycleX.fromName(json['billing_cycle'] as String?),
      nextRenewalDate: DateTime.parse(json['next_renewal_date'] as String),
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Insert and update body. user_id is left to the database (defaults to
  /// auth.uid(), and RLS rejects any other value).
  static Map<String, dynamic> writeJson({
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
    return {
      'catalog_id': catalogId,
      'custom_name': customName,
      'plan_name': planName,
      'category': category.name,
      'price': price,
      'currency': currency,
      'billing_cycle': billingCycle.name,
      'next_renewal_date': _isoDate(nextRenewalDate),
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  /// Full row for the offline cache; round-trips through [UserSubscriptionModel.fromJson].
  Map<String, dynamic> toCacheJson() => {
    'id': id,
    ...writeJson(
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
    ),
    'created_at': createdAt?.toIso8601String(),
    'subscription_catalog': catalogId == null
        ? null
        : {'name': catalogName, 'domain': domain, 'logo_url': logoUrl},
  };

  static String _isoDate(DateTime date) =>
      date.toIso8601String().split('T').first;
}
