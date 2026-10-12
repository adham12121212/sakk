import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/domain/subscription_totals.dart';

UserSubscription sub({
  String id = 's1',
  double price = 120,
  String currency = 'EGP',
  BillingCycle cycle = BillingCycle.monthly,
  DateTime? renewal,
  String? catalogId,
  String? customName,
  String? catalogName,
  String? planName,
}) =>
    UserSubscription(
      id: id,
      catalogId: catalogId,
      customName: customName,
      catalogName: catalogName,
      planName: planName,
      price: price,
      currency: currency,
      billingCycle: cycle,
      nextRenewalDate: renewal ?? DateTime(2026, 11, 1),
    );

void main() {
  test('monthlyCost spreads a yearly price over 12 months', () {
    expect(sub(price: 120).monthlyCost, 120);
    expect(sub(price: 1200, cycle: BillingCycle.yearly).monthlyCost, 100);
  });

  test('daysLeft counts calendar days and ignores the time of day', () {
    final s = sub(renewal: DateTime(2026, 10, 15));
    expect(s.daysLeft(DateTime(2026, 10, 12, 23, 59)), 3);
    expect(s.daysLeft(DateTime(2026, 10, 15, 8)), 0);
    expect(s.daysLeft(DateTime(2026, 10, 16)), -1);
  });

  test('daysLeft is not thrown off by a daylight saving change', () {
    // Egypt moves clocks back on the last Thursday of October.
    expect(sub(renewal: DateTime(2026, 11, 2)).daysLeft(DateTime(2026, 10, 28)), 5);
  });

  test('name prefers the custom name, then the catalog service', () {
    expect(sub(customName: 'Gym').name, 'Gym');
    expect(sub(catalogId: 'c1', catalogName: 'Netflix', planName: 'Premium').name, 'Netflix');
    expect(sub(catalogId: 'c1', planName: 'Premium').name, 'Premium');
    expect(sub(catalogId: 'c1').isCustom, isFalse);
    expect(sub(customName: 'Gym').isCustom, isTrue);
  });

  test('monthly totals are kept per currency', () {
    final totals = monthlyTotalsByCurrency([
      sub(price: 240),
      sub(price: 1200, cycle: BillingCycle.yearly),
      sub(price: 20, currency: 'USD'),
    ]);
    expect(totals, {'EGP': 340, 'USD': 20});
    expect(monthlyTotalsByCurrency(const []), isEmpty);
  });

  test('sortedByRenewal puts the nearest renewal first', () {
    final sorted = sortedByRenewal([
      sub(id: 'late', renewal: DateTime(2026, 12, 1)),
      sub(id: 'soon', renewal: DateTime(2026, 10, 13)),
      sub(id: 'mid', renewal: DateTime(2026, 11, 1)),
    ]);
    expect(sorted.map((s) => s.id), ['soon', 'mid', 'late']);
  });
}
