import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/installments/domain/entities/installment_payment.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan.dart';
import 'package:sakk/features/installments/domain/installment_totals.dart';

import 'installment_fixtures.dart';

void main() {
  final today = DateTime(2027, 1, 10);

  group('InstallmentPlan', () {
    // 12 x 1000 from Nov 5 2026, 2000 down; first 2 paid.
    final p = plan('a', t: terms(total: 14000, down: 2000, count: 12), paid: {0, 1});

    test('works out paid, remaining and progress from its payments', () {
      expect(p.paidCount, 2);
      expect(p.totalCount, 12);
      expect(p.paidAmount, 4000);
      expect(p.remainingBalance, 10000);
      expect(p.totalPayable, 14000);
      expect(p.progress, closeTo(4000 / 14000, 1e-9));
    });

    test('the next payment is the earliest unpaid, overdue ones included', () {
      expect(p.nextPayment!.id, 'a-p2');
      expect(p.nextDueDate, DateTime(2027, 1, 5));
      expect(p.nextPayment!.daysLeft(today), -5);
      expect(p.overduePayments(today).map((x) => x.id), ['a-p2']);
      expect(p.overdueAmount(today), 1000);
      expect(p.status, InstallmentPlanStatus.active);
    });

    test('completed once every payment is paid, cancelled when stored', () {
      final done = plan('b', t: terms(count: 2, total: 2000), paid: {0, 1});
      expect(done.status, InstallmentPlanStatus.completed);
      expect(done.nextPayment, isNull);
      expect(done.progress, 1);
      expect(done.isActive, isFalse);
      expect(plan('c', cancelled: true, paid: {0, 1}).status, InstallmentPlanStatus.cancelled);
    });

    test('marking a payment unpaid again makes a completed plan active', () {
      final done = plan('b', t: terms(count: 2, total: 2000), paid: {0, 1});
      final reopened = done.withPayment(done.payments.last.withPaidAt(null));
      expect(reopened.status, InstallmentPlanStatus.active);
      expect(reopened.nextPayment!.id, 'b-p1');
      expect(reopened.remainingBalance, 1000);
    });

    test('shows the product name when one is linked, its title otherwise', () {
      expect(p.name, 'a');
      final linked = InstallmentPlan(id: 'x', title: 'Old name', productName: 'iPhone', terms: terms());
      expect(linked.name, 'iPhone');
    });
  });

  group('InstallmentPayment.status', () {
    final payment = InstallmentPayment(id: 'p', planId: 'a', dueDate: DateTime(2027, 1, 10), amount: 1);
    test('pending on and before the due day, overdue after it, paid once paid', () {
      expect(payment.status(DateTime(2027, 1, 10, 23)), PaymentStatus.pending);
      expect(payment.status(DateTime(2027, 1, 11)), PaymentStatus.overdue);
      expect(payment.withPaidAt(DateTime(2027, 1, 12)).status(DateTime(2027, 1, 20)), PaymentStatus.paid);
    });
  });

  group('totals', () {
    final egp = plan('egp', t: terms(total: 12000), paid: {0});
    final usd = plan('usd', t: terms(total: 600, count: 6), currency: 'USD');
    final done = plan('done', t: terms(count: 1, total: 500), paid: {0});
    final cancelled = plan('cancelled', cancelled: true);

    test('remaining per currency counts active plans only', () {
      expect(remainingByCurrency([egp, usd, done, cancelled]), {'EGP': 11000, 'USD': 600});
    });

    test('active by next due date, then completed, then cancelled', () {
      final later = plan('later', t: terms(start: DateTime(2026, 12, 1)));
      final overdue = plan('overdue', t: terms(start: DateTime(2026, 9, 1)));
      final sorted = sortedByNextDue([cancelled, later, done, egp, overdue]);
      expect(sorted.map((p) => p.id), ['overdue', 'later', 'egp', 'done', 'cancelled']);
    });

    test('finds the plans linked to a product', () {
      final linked = plan('linked', productId: 'prod-1');
      expect(plansForProductIn([egp, linked], 'prod-1').map((p) => p.id), ['linked']);
    });
  });
}
