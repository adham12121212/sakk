import 'package:equatable/equatable.dart';

import '../../installments/domain/entities/installment_plan.dart';
import '../../products/domain/entities/product_entity.dart';
import '../../subscriptions/domain/entities/user_subscription.dart';
import '../../subscriptions/domain/renewal_schedule.dart';

enum SummaryPaymentKind { renewal, installment }

/// One payment still to make this month.
class SummaryPayment extends Equatable {
  const SummaryPayment({
    required this.kind,
    required this.name,
    required this.amount,
    required this.currency,
    required this.date,
    this.isOverdue = false,
    this.planId,
  });

  final SummaryPaymentKind kind;
  final String name;
  final double amount;
  final String currency;
  final DateTime date;

  /// An installment whose due date already passed unpaid.
  final bool isOverdue;

  /// The installment plan, to open it.
  final String? planId;

  @override
  List<Object?> get props => [
    kind,
    name,
    amount,
    currency,
    date,
    isOverdue,
    planId,
  ];
}

/// "What will I pay this month": subscription renewals and unpaid
/// installments from today to the end of the month (overdue installments
/// included), and warranties ending soon. Totals are per currency: the app
/// has no exchange rates.
class MonthlySummary extends Equatable {
  const MonthlySummary({
    required this.totals,
    required this.subscriptionTotals,
    required this.installmentTotals,
    required this.payments,
    required this.expiringWarranties,
  });

  final Map<String, double> totals;
  final Map<String, double> subscriptionTotals;
  final Map<String, double> installmentTotals;

  /// Oldest first (overdue ones lead).
  final List<SummaryPayment> payments;

  /// Products whose warranty ends within [warrantyWindowDays], soonest first.
  final List<ProductEntity> expiringWarranties;

  static const warrantyWindowDays = 60;

  factory MonthlySummary.build({
    required Iterable<UserSubscription> subscriptions,
    required Iterable<InstallmentPlan> plans,
    required Iterable<ProductEntity> products,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final monthEnd = DateTime(day.year, day.month + 1, 0);
    final payments = <SummaryPayment>[];

    for (final s in subscriptions) {
      final renews = nextRenewalOnOrAfter(
        s.nextRenewalDate,
        s.billingCycle,
        day,
      );
      if (renews.isAfter(monthEnd)) continue;
      payments.add(
        SummaryPayment(
          kind: SummaryPaymentKind.renewal,
          name: s.name,
          amount: s.price,
          currency: s.currency,
          date: renews,
        ),
      );
    }

    for (final plan in plans.where((p) => p.isActive)) {
      for (final p in plan.unpaidPayments) {
        final due = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
        if (due.isAfter(monthEnd)) continue;
        payments.add(
          SummaryPayment(
            kind: SummaryPaymentKind.installment,
            name: plan.name,
            amount: p.amount,
            currency: plan.currency,
            date: due,
            isOverdue: due.isBefore(day),
            planId: plan.id,
          ),
        );
      }
    }
    payments.sort((a, b) => a.date.compareTo(b.date));

    Map<String, double> sum(Iterable<SummaryPayment> ps) {
      final totals = <String, double>{};
      for (final p in ps) {
        totals.update(
          p.currency,
          (v) => v + p.amount,
          ifAbsent: () => p.amount,
        );
      }
      return totals;
    }

    final windowEnd = day.add(const Duration(days: warrantyWindowDays));
    final expiring = products.where((p) {
      final end = p.warrantyEndDate;
      return !end.isBefore(day) && !end.isAfter(windowEnd);
    }).toList()..sort((a, b) => a.warrantyEndDate.compareTo(b.warrantyEndDate));

    return MonthlySummary(
      totals: sum(payments),
      subscriptionTotals: sum(
        payments.where((p) => p.kind == SummaryPaymentKind.renewal),
      ),
      installmentTotals: sum(
        payments.where((p) => p.kind == SummaryPaymentKind.installment),
      ),
      payments: payments,
      expiringWarranties: expiring,
    );
  }

  @override
  List<Object?> get props => [
    totals,
    subscriptionTotals,
    installmentTotals,
    payments,
    expiringWarranties,
  ];
}
