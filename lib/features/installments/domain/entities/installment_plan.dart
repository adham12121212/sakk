import 'package:equatable/equatable.dart';

import 'installment_payment.dart';
import 'installment_plan_draft.dart';
import 'installment_terms.dart';

/// Where a plan stands. Only cancelled is stored; completed is every
/// installment being paid.
enum InstallmentPlanStatus { active, completed, cancelled }

/// A purchase being paid off in installments.
///
/// Remaining balance, paid count, next due date and progress are worked out
/// from [payments], never stored.
class InstallmentPlan extends Equatable {
  final String id;

  /// Null when no product is linked, or the linked product was deleted.
  final String? productId;

  /// The linked product's current name, when it has one.
  final String? productName;
  final String title;
  final String? provider;
  final String currency;
  final InstallmentTerms terms;
  final String? notes;
  final bool isCancelled;
  final DateTime? createdAt;

  /// Every installment, earliest due first.
  final List<InstallmentPayment> payments;

  const InstallmentPlan({
    required this.id,
    this.productId,
    this.productName,
    required this.title,
    this.provider,
    this.currency = 'EGP',
    required this.terms,
    this.notes,
    this.isCancelled = false,
    this.createdAt,
    this.payments = const [],
  });

  /// What to show as the title: the product's name follows a rename.
  String get name => productName ?? title;

  int get paidCount => payments.where((p) => p.isPaid).length;
  int get totalCount => payments.length;

  /// Unpaid installments, earliest due first (overdue ones included).
  List<InstallmentPayment> get unpaidPayments =>
      payments.where((p) => !p.isPaid).toList();

  /// The earliest unpaid installment, overdue or not; null once all are paid.
  InstallmentPayment? get nextPayment {
    for (final p in payments) {
      if (!p.isPaid) return p;
    }
    return null;
  }

  DateTime? get nextDueDate => nextPayment?.dueDate;

  /// The down payment plus every paid installment.
  double get paidAmount =>
      terms.downPayment +
      payments.where((p) => p.isPaid).fold(0.0, (sum, p) => sum + p.amount);

  /// Every unpaid installment.
  double get remainingBalance =>
      payments.where((p) => !p.isPaid).fold(0.0, (sum, p) => sum + p.amount);

  /// The down payment plus every installment.
  double get totalPayable => paidAmount + remainingBalance;

  /// Share of [totalPayable] paid so far, 0–1.
  double get progress {
    final total = totalPayable;
    if (total <= 0) return payments.isEmpty ? 0 : 1;
    return (paidAmount / total).clamp(0, 1).toDouble();
  }

  List<InstallmentPayment> overduePayments(DateTime today) =>
      payments.where((p) => p.isOverdue(today)).toList();

  double overdueAmount(DateTime today) =>
      overduePayments(today).fold(0.0, (sum, p) => sum + p.amount);

  bool get isCompleted => payments.isNotEmpty && nextPayment == null;

  InstallmentPlanStatus get status {
    if (isCancelled) return InstallmentPlanStatus.cancelled;
    if (isCompleted) return InstallmentPlanStatus.completed;
    return InstallmentPlanStatus.active;
  }

  /// Still being paid: not cancelled and not completed. Only these count in
  /// totals and get reminders.
  bool get isActive => status == InstallmentPlanStatus.active;

  /// The plan as the form edits it.
  InstallmentPlanDraft toDraft() => InstallmentPlanDraft(
    productId: productId,
    title: title,
    provider: provider,
    currency: currency,
    terms: terms,
    notes: notes,
    isCancelled: isCancelled,
  );

  /// This plan with [payment] swapped in (after it was marked paid/unpaid).
  InstallmentPlan withPayment(InstallmentPayment payment) => InstallmentPlan(
    id: id,
    productId: productId,
    productName: productName,
    title: title,
    provider: provider,
    currency: currency,
    terms: terms,
    notes: notes,
    isCancelled: isCancelled,
    createdAt: createdAt,
    payments: [for (final p in payments) p.id == payment.id ? payment : p],
  );

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    title,
    provider,
    currency,
    terms,
    notes,
    isCancelled,
    createdAt,
    payments,
  ];
}
