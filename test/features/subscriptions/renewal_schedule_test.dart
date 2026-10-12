import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/renewal_schedule.dart';

void main() {
  group('addMonthsClamped', () {
    test('keeps the day when the month has it', () {
      expect(addMonthsClamped(DateTime(2026, 3, 15), 1), DateTime(2026, 4, 15));
    });

    test('uses the last day of a shorter month', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    });

    test('crosses year boundaries', () {
      expect(addMonthsClamped(DateTime(2026, 11, 30), 3), DateTime(2027, 2, 28));
      expect(addMonthsClamped(DateTime(2028, 2, 29), 12), DateTime(2029, 2, 28));
    });
  });

  group('nextRenewalOnOrAfter', () {
    final today = DateTime(2026, 10, 12, 18, 30);

    test('a renewal today or later is unchanged', () {
      expect(nextRenewalOnOrAfter(DateTime(2026, 10, 12), BillingCycle.monthly, today), DateTime(2026, 10, 12));
      expect(nextRenewalOnOrAfter(DateTime(2026, 12, 1), BillingCycle.yearly, today), DateTime(2026, 12, 1));
    });

    test('a passed monthly renewal moves to the next one on or after today', () {
      expect(nextRenewalOnOrAfter(DateTime(2026, 10, 11), BillingCycle.monthly, today), DateTime(2026, 11, 11));
      expect(nextRenewalOnOrAfter(DateTime(2026, 9, 12), BillingCycle.monthly, today), DateTime(2026, 10, 12));
      expect(nextRenewalOnOrAfter(DateTime(2026, 9, 20), BillingCycle.monthly, today), DateTime(2026, 10, 20));
    });

    test('skips several missed cycles at once', () {
      expect(nextRenewalOnOrAfter(DateTime(2024, 5, 3), BillingCycle.monthly, today), DateTime(2026, 11, 3));
      expect(nextRenewalOnOrAfter(DateTime(2023, 6, 1), BillingCycle.yearly, today), DateTime(2027, 6, 1));
      expect(nextRenewalOnOrAfter(DateTime(2025, 10, 12), BillingCycle.yearly, today), DateTime(2026, 10, 12));
    });

    test('counts from the original day, so the 31st does not drift', () {
      // Jan 31 → (Feb 28) → Mar 31, not Mar 28.
      expect(
        nextRenewalOnOrAfter(DateTime(2026, 1, 31), BillingCycle.monthly, DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31),
      );
      expect(
        nextRenewalOnOrAfter(DateTime(2026, 1, 31), BillingCycle.monthly, DateTime(2026, 2, 2)),
        DateTime(2026, 2, 28),
      );
    });
  });
}
