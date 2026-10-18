import 'package:equatable/equatable.dart';

import '../../../../core/util/date_math.dart';

/// Where an installment stands. Only paid/pending is stored; overdue is a
/// pending one whose due date has passed.
enum PaymentStatus { pending, paid, overdue }

/// One installment of a plan.
class InstallmentPayment extends Equatable {
  final String id;
  final String planId;

  /// Date only (no time of day).
  final DateTime dueDate;
  final double amount;

  /// When the user marked it paid; null while it's unpaid.
  final DateTime? paidAt;

  const InstallmentPayment({
    required this.id,
    required this.planId,
    required this.dueDate,
    required this.amount,
    this.paidAt,
  });

  bool get isPaid => paidAt != null;

  /// Days from [today] until it's due; 0 on the day itself, negative once
  /// it has passed.
  int daysLeft(DateTime today) => daysBetween(today, dueDate);

  bool isOverdue(DateTime today) => !isPaid && daysLeft(today) < 0;

  PaymentStatus status(DateTime today) {
    if (isPaid) return PaymentStatus.paid;
    return isOverdue(today) ? PaymentStatus.overdue : PaymentStatus.pending;
  }

  /// Marked paid at [paidAt], or unpaid again when it's null.
  InstallmentPayment withPaidAt(DateTime? paidAt) => InstallmentPayment(
    id: id,
    planId: planId,
    dueDate: dueDate,
    amount: amount,
    paidAt: paidAt,
  );

  @override
  List<Object?> get props => [id, planId, dueDate, amount, paidAt];
}
