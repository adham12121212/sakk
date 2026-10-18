import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/pro/domain/monthly_summary.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';

import '../installments/installment_fixtures.dart';

UserSubscription sub(String name, double price, DateTime renewal,
        {BillingCycle cycle = BillingCycle.monthly, String currency = 'EGP'}) =>
    UserSubscription(
      id: name,
      customName: name,
      price: price,
      currency: currency,
      billingCycle: cycle,
      nextRenewalDate: renewal,
    );

ProductEntity product(String name, DateTime bought, int months) =>
    ProductEntity(id: name, name: name, purchaseDate: bought, warrantyMonths: months);

void main() {
  final today = DateTime(2026, 10, 18);

  test('renewals and unpaid installments left this month, overdue included, per currency', () {
    final summary = MonthlySummary.build(
      today: today,
      subscriptions: [
        sub('Netflix', 240, DateTime(2026, 10, 25)),
        // Renewed on the 2nd: next one is in November, not this month.
        sub('Spotify', 80, DateTime(2026, 10, 2)),
        sub('ChatGPT', 20, DateTime(2026, 10, 30), currency: 'USD'),
        sub('Microsoft 365', 1300, DateTime(2027, 3, 1), cycle: BillingCycle.yearly),
      ],
      plans: [
        // Due on the 5th each month from Sep 5: Sep paid, Oct 5 overdue,
        // Nov 5 next month.
        plan('Phone', t: terms(total: 12000, count: 12, start: DateTime(2026, 9, 5)), paid: {0}),
        plan('Old TV', t: terms(start: DateTime(2026, 10, 20)), cancelled: true),
      ],
      products: const [],
    );

    expect(summary.payments.map((p) => p.name), ['Phone', 'Netflix', 'ChatGPT']);
    final phone = summary.payments.first;
    expect(phone.isOverdue, isTrue);
    expect(phone.kind, SummaryPaymentKind.installment);
    expect(phone.planId, 'Phone');
    expect(summary.subscriptionTotals, {'EGP': 240, 'USD': 20});
    expect(summary.installmentTotals, {'EGP': 1000});
    expect(summary.totals, {'EGP': 1240, 'USD': 20});
  });

  test('nothing due: empty totals', () {
    final summary = MonthlySummary.build(
      today: today,
      subscriptions: [sub('Netflix', 240, DateTime(2026, 11, 1))],
      plans: const [],
      products: const [],
    );
    expect(summary.payments, isEmpty);
    expect(summary.totals, isEmpty);
  });

  test('warranties ending within 60 days, soonest first; ended ones left out', () {
    final summary = MonthlySummary.build(
      today: today,
      subscriptions: const [],
      plans: const [],
      products: [
        product('Fridge', DateTime(2024, 12, 1), 24), // ends 2026-12-01
        product('TV', DateTime(2025, 11, 1), 12), // ends 2026-11-01
        product('Laptop', DateTime(2025, 1, 1), 12), // ended
        product('Watch', DateTime(2026, 1, 1), 24), // 2028
      ],
    );
    expect(summary.expiringWarranties.map((p) => p.name), ['TV', 'Fridge']);
  });
}
