import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/installments/domain/entities/scheduled_payment.dart';
import 'package:sakk/features/installments/domain/installment_schedule.dart';

import 'installment_fixtures.dart';

List<DateTime> dates(List<ScheduledPayment> s) => [for (final p in s) p.dueDate];
List<double> amounts(List<ScheduledPayment> s) => [for (final p in s) p.amount];

void main() {
  group('installmentDueDate', () {
    test('the first is due on the start date, later ones on the due day', () {
      final start = DateTime(2026, 11, 10);
      expect(installmentDueDate(start, 5, 0), DateTime(2026, 11, 10));
      expect(installmentDueDate(start, 5, 1), DateTime(2026, 12, 5));
      expect(installmentDueDate(start, 5, 2), DateTime(2027, 1, 5));
    });

    test('days 29-31 fall on the last day of short months without drifting', () {
      final schedule = buildSchedule(terms(start: DateTime(2026, 12, 31), count: 4));
      expect(dates(schedule), [
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
      ]);
      expect(installmentDueDate(DateTime(2028, 1, 30), 30, 1), DateTime(2028, 2, 29));
      expect(installmentDueDate(DateTime(2026, 1, 29), 29, 1), DateTime(2026, 2, 28));
      expect(installmentDueDate(DateTime(2026, 3, 31), 31, 1), DateTime(2026, 4, 30));
    });

    test('ignores the time of day of the start date', () {
      expect(installmentDueDate(DateTime(2026, 11, 5, 18, 30), 5, 0), DateTime(2026, 11, 5));
    });
  });

  group('buildSchedule', () {
    test('an even split adds up exactly: the last takes the rounding', () {
      final schedule = buildSchedule(terms(total: 10000, count: 3));
      expect(amounts(schedule), [3333.33, 3333.33, 3333.34]);
      expect(amounts(schedule).reduce((a, b) => a + b), closeTo(10000, 0.001));
    });

    test('financed amount is price less down payment plus fees', () {
      final t = terms(total: 30000, down: 6000, fees: 2400, count: 12);
      expect(t.financedAmount, 26400);
      expect(suggestedInstallmentAmount(t), 2200);
      expect(amounts(buildSchedule(t)), List.filled(12, 2200.0));
    });

    test('an amount the user typed is kept as it is', () {
      final schedule = buildSchedule(terms(total: 10000, count: 3, amount: 3500));
      expect(amounts(schedule), [3500, 3500, 3500]);
    });

    test('nothing to build without a count or an amount', () {
      expect(buildSchedule(terms(count: 0, amount: 100)), isEmpty);
      expect(suggestedAmountFor(0, 3), isNull);
      expect(suggestedAmountFor(100, 0), isNull);
    });
  });

  group('unpaidScheduleForEdit', () {
    test('same terms keep the unpaid installments exactly', () {
      final p = plan('a', paid: {0, 1});
      final unpaid = unpaidScheduleForEdit(p, p.terms);
      expect(unpaid.length, 10);
      expect(unpaid.first.dueDate, p.payments[2].dueDate);
    });

    test('new terms move only the unpaid places', () {
      // Paid the 1st and 3rd; the 2nd is still unpaid.
      final p = plan('a', t: terms(count: 4, total: 4000), paid: {0, 2});
      final edited = terms(count: 4, total: 4000, start: DateTime(2026, 11, 20));
      final unpaid = unpaidScheduleForEdit(p, edited);
      expect(dates(unpaid), [DateTime(2026, 12, 20), DateTime(2027, 2, 20)]);
    });

    test('more installments add places at the end', () {
      final p = plan('a', t: terms(count: 3, total: 3000), paid: {0});
      final unpaid = unpaidScheduleForEdit(p, terms(count: 5, total: 3000, amount: 600));
      expect(unpaid.length, 4);
      expect(amounts(unpaid), [600, 600, 600, 600]);
      expect(unpaid.last.dueDate, DateTime(2027, 3, 5));
    });

    test('fewer installments than a paid place still fills the count', () {
      // Paid only the 5th; down to 4 installments leaves 3 unpaid.
      final p = plan('a', t: terms(count: 5, total: 5000), paid: {4});
      final unpaid = unpaidScheduleForEdit(p, terms(count: 4, total: 5000));
      expect(unpaid.length, 3);
      expect(minimumInstallmentsCount(p), 1);
    });

    test('the count cannot go below the installments paid', () {
      expect(minimumInstallmentsCount(plan('a', paid: {0, 1, 2})), 3);
      expect(minimumInstallmentsCount(plan('a')), 1);
    });
  });
}
