import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/subscriptions/data/models/catalog_service_model.dart';
import 'package:sakk/features/subscriptions/data/models/user_subscription_model.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/subscription_category.dart';

/// A user_subscriptions row as Supabase returns it with UserSubscriptionModel.selectColumns.
Map<String, dynamic> subscriptionRow() => {
      'id': 's1',
      'user_id': 'u1',
      'catalog_id': 'c1',
      'custom_name': null,
      'plan_name': 'Premium',
      'category': 'streaming',
      'price': 240,
      'currency': 'EGP',
      'billing_cycle': 'monthly',
      'next_renewal_date': '2026-11-01',
      'payment_method': 'Visa •• 4242',
      'notes': null,
      'created_at': '2026-10-12T10:00:00Z',
      'updated_at': '2026-10-12T10:00:00Z',
      'subscription_catalog': {'name': 'Netflix', 'domain': 'netflix.com', 'logo_url': null},
    };

Map<String, dynamic> catalogRow() => {
      'id': 'c1',
      'name': 'Netflix',
      'category': 'streaming',
      'domain': 'netflix.com',
      'logo_url': null,
      'is_active': true,
      'created_at': '2026-10-12T10:00:00Z',
      'plans': [
        {'name': 'Basic', 'price': 120, 'currency': 'EGP', 'billing_cycle': 'monthly'},
        {'name': 'Yearly', 'price': 99.5, 'currency': 'USD', 'billing_cycle': 'yearly'},
      ],
    };

void main() {
  group('UserSubscriptionModel', () {
    test('reads a row with its catalog service embedded', () {
      final s = UserSubscriptionModel.fromJson(subscriptionRow());
      expect(s.name, 'Netflix');
      expect(s.domain, 'netflix.com');
      expect(s.planName, 'Premium');
      expect(s.category, SubscriptionCategory.streaming);
      expect(s.price, 240.0);
      expect(s.billingCycle, BillingCycle.monthly);
      expect(s.nextRenewalDate, DateTime(2026, 11, 1));
      expect(s.paymentMethod, 'Visa •• 4242');
    });

    test('a custom subscription has no catalog service', () {
      final s = UserSubscriptionModel.fromJson({
        ...subscriptionRow(),
        'catalog_id': null,
        'custom_name': 'Gym',
        'subscription_catalog': null,
        'category': 'not-a-category',
        'billing_cycle': 'yearly',
      });
      expect(s.isCustom, isTrue);
      expect(s.name, 'Gym');
      expect(s.domain, isNull);
      expect(s.category, SubscriptionCategory.other);
      expect(s.billingCycle, BillingCycle.yearly);
    });

    test('round-trips through the offline cache', () {
      final s = UserSubscriptionModel.fromJson(subscriptionRow());
      final cached = UserSubscriptionModel.fromJson(
        jsonDecode(jsonEncode(s.toCacheJson())) as Map<String, dynamic>,
      );
      expect(cached, s);
    });

    test('writeJson sends a date-only renewal and never a user id', () {
      final json = UserSubscriptionModel.writeJson(
        customName: 'Gym',
        category: SubscriptionCategory.other,
        price: 500,
        currency: 'EGP',
        billingCycle: BillingCycle.monthly,
        nextRenewalDate: DateTime(2026, 11, 5, 14, 30),
      );
      expect(json['next_renewal_date'], '2026-11-05');
      expect(json['billing_cycle'], 'monthly');
      expect(json.containsKey('user_id'), isFalse);
    });
  });

  group('CatalogServiceModel', () {
    test('reads its plans', () {
      final c = CatalogServiceModel.fromJson(catalogRow());
      expect(c.plans, hasLength(2));
      expect(c.plans.last.price, 99.5);
      expect(c.plans.last.currency, 'USD');
      expect(c.plans.last.billingCycle, BillingCycle.yearly);
    });

    test('round-trips through the offline cache', () {
      final c = CatalogServiceModel.fromJson(catalogRow());
      final cached = CatalogServiceModel.fromJson(
        jsonDecode(jsonEncode(c.toCacheJson())) as Map<String, dynamic>,
      );
      expect(cached, c);
    });
  });
}
