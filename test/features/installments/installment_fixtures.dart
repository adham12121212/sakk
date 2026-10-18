import 'package:sakk/features/installments/domain/entities/installment_payment.dart';
import 'package:sakk/features/installments/domain/entities/installment_plan.dart';
import 'package:sakk/features/installments/domain/entities/installment_terms.dart';
import 'package:sakk/features/installments/domain/installment_schedule.dart';

InstallmentTerms terms({
  double total = 12000,
  double down = 0,
  double? fees,
  double? amount,
  int count = 12,
  DateTime? start,
  int? dueDay,
}) {
  final startDate = start ?? DateTime(2026, 11, 5);
  final financed = total - down + (fees ?? 0);
  return InstallmentTerms(
    totalPrice: total,
    downPayment: down,
    interestOrFees: fees,
    installmentAmount: amount ?? suggestedAmountFor(financed, count)!,
    installmentsCount: count,
    startDate: startDate,
    dueDayOfMonth: dueDay ?? startDate.day,
  );
}

/// A saved plan whose payments follow [t]; [paid] are the places (0 = first)
/// already paid.
InstallmentPlan plan(
  String id, {
  InstallmentTerms? t,
  Set<int> paid = const {},
  String currency = 'EGP',
  bool cancelled = false,
  String? productId,
  DateTime? createdAt,
}) {
  final planTerms = t ?? terms();
  final schedule = buildSchedule(planTerms);
  return InstallmentPlan(
    id: id,
    productId: productId,
    title: id,
    currency: currency,
    terms: planTerms,
    isCancelled: cancelled,
    createdAt: createdAt,
    payments: [
      for (var i = 0; i < schedule.length; i++)
        InstallmentPayment(
          id: '$id-p$i',
          planId: id,
          dueDate: schedule[i].dueDate,
          amount: schedule[i].amount,
          paidAt: paid.contains(i) ? DateTime(2026, 10, 1) : null,
        ),
    ],
  );
}
