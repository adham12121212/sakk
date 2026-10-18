import '../../domain/entities/installment_payment.dart';

class InstallmentPaymentModel extends InstallmentPayment {
  const InstallmentPaymentModel({
    required super.id,
    required super.planId,
    required super.dueDate,
    required super.amount,
    super.paidAt,
  });

  factory InstallmentPaymentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentPaymentModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }

  factory InstallmentPaymentModel.from(InstallmentPayment p) =>
      p is InstallmentPaymentModel
      ? p
      : InstallmentPaymentModel(
          id: p.id,
          planId: p.planId,
          dueDate: p.dueDate,
          amount: p.amount,
          paidAt: p.paidAt,
        );

  /// Update body for marking it paid at [paidAt], or unpaid when it's null.
  static Map<String, dynamic> paidJson(DateTime? paidAt) => {
    'status': paidAt == null ? 'pending' : 'paid',
    'paid_at': paidAt?.toUtc().toIso8601String(),
  };

  /// Full row for the offline cache; round-trips through [InstallmentPaymentModel.fromJson].
  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'plan_id': planId,
    'due_date': isoDate(dueDate),
    'amount': amount,
    ...paidJson(paidAt),
  };

  static String isoDate(DateTime date) =>
      date.toIso8601String().split('T').first;
}
