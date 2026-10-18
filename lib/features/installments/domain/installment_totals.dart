import 'entities/installment_plan.dart';

/// What's left to pay on active plans, per currency. The app has no exchange
/// rates, so currencies are never added together.
Map<String, double> remainingByCurrency(Iterable<InstallmentPlan> plans) {
  final totals = <String, double>{};
  for (final p in plans.where((p) => p.isActive)) {
    totals.update(
      p.currency,
      (sum) => sum + p.remainingBalance,
      ifAbsent: () => p.remainingBalance,
    );
  }
  return totals;
}

/// Active plans by their next installment (overdue ones first), then
/// completed, then cancelled ones, newest first.
List<InstallmentPlan> sortedByNextDue(Iterable<InstallmentPlan> plans) {
  int rank(InstallmentPlan p) => switch (p.status) {
    InstallmentPlanStatus.active => 0,
    InstallmentPlanStatus.completed => 1,
    InstallmentPlanStatus.cancelled => 2,
  };
  return plans.toList()..sort((a, b) {
    final byStatus = rank(a).compareTo(rank(b));
    if (byStatus != 0) return byStatus;
    final aDue = a.nextDueDate, bDue = b.nextDueDate;
    if (aDue != null && bDue != null && aDue != bDue) return aDue.compareTo(bDue);
    final aCreated = a.createdAt, bCreated = b.createdAt;
    if (aCreated != null && bCreated != null) return bCreated.compareTo(aCreated);
    return a.id.compareTo(b.id);
  });
}

/// The plans linked to the product [productId], in [sortedByNextDue] order.
List<InstallmentPlan> plansForProductIn(
  Iterable<InstallmentPlan> plans,
  String productId,
) => sortedByNextDue(plans.where((p) => p.productId == productId));

/// Unpaid installments of active plans due in [month] of [year], per
/// currency.
Map<String, double> dueInMonthByCurrency(
  Iterable<InstallmentPlan> plans,
  int year,
  int month,
) {
  final totals = <String, double>{};
  for (final plan in plans.where((p) => p.isActive)) {
    for (final p in plan.unpaidPayments) {
      if (p.dueDate.year != year || p.dueDate.month != month) continue;
      totals.update(plan.currency, (sum) => sum + p.amount, ifAbsent: () => p.amount);
    }
  }
  return totals;
}

/// Unpaid installments of active plans past their due date, per currency.
Map<String, double> overdueByCurrency(
  Iterable<InstallmentPlan> plans,
  DateTime today,
) {
  final totals = <String, double>{};
  for (final plan in plans.where((p) => p.isActive)) {
    final overdue = plan.overdueAmount(today);
    if (overdue <= 0) continue;
    totals.update(plan.currency, (sum) => sum + overdue, ifAbsent: () => overdue);
  }
  return totals;
}
