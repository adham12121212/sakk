import '../../domain/entities/installment_payment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/installment_plan_draft.dart';
import '../../domain/entities/installment_terms.dart';
import '../../domain/entities/scheduled_payment.dart';
import 'installment_payment_model.dart';

class InstallmentPlanModel extends InstallmentPlan {
  const InstallmentPlanModel({
    required super.id,
    super.productId,
    super.productName,
    required super.title,
    super.provider,
    super.currency,
    required super.terms,
    super.notes,
    super.isCancelled,
    super.createdAt,
    List<InstallmentPaymentModel> super.payments = const [],
  });

  /// Columns to select so a plan arrives with its payments and its linked
  /// product's name embedded (PostgREST follows the foreign keys).
  static const selectColumns = '*, installment_payments(*), products(name)';

  @override
  List<InstallmentPaymentModel> get payments =>
      super.payments.cast<InstallmentPaymentModel>();

  factory InstallmentPlanModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final payments = [
      for (final row in (json['installment_payments'] as List? ?? const []))
        InstallmentPaymentModel.fromJson(row as Map<String, dynamic>),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return InstallmentPlanModel(
      id: json['id'] as String,
      productId: json['product_id'] as String?,
      productName: product?['name'] as String?,
      title: json['title'] as String,
      provider: json['provider'] as String?,
      currency: json['currency'] as String? ?? 'EGP',
      terms: InstallmentTerms(
        totalPrice: (json['total_price'] as num).toDouble(),
        downPayment: (json['down_payment'] as num?)?.toDouble() ?? 0,
        interestOrFees: (json['interest_or_fees'] as num?)?.toDouble(),
        installmentAmount: (json['installment_amount'] as num).toDouble(),
        installmentsCount: json['installments_count'] as int,
        startDate: DateTime.parse(json['start_date'] as String),
        dueDayOfMonth: json['due_day_of_month'] as int,
      ),
      notes: json['notes'] as String?,
      isCancelled: json['status'] == 'cancelled',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      payments: payments,
    );
  }

  /// The plan for save_installment_plan's p_plan. user_id is left to the
  /// database (defaults to auth.uid(), and RLS rejects any other value).
  static Map<String, dynamic> writeJson(
    InstallmentPlanDraft draft, {
    String? id,
  }) {
    final terms = draft.terms;
    return {
      'id': ?id,
      'product_id': draft.productId,
      'title': draft.title,
      'provider': draft.provider,
      'currency': draft.currency,
      'total_price': terms.totalPrice,
      'down_payment': terms.downPayment,
      'interest_or_fees': terms.interestOrFees,
      'installment_amount': terms.installmentAmount,
      'installments_count': terms.installmentsCount,
      'start_date': InstallmentPaymentModel.isoDate(terms.startDate),
      'due_day_of_month': terms.dueDayOfMonth,
      'notes': draft.notes,
      'status': draft.isCancelled ? 'cancelled' : 'active',
    };
  }

  /// The unpaid installments for save_installment_plan's p_payments.
  static List<Map<String, dynamic>> paymentsJson(
    List<ScheduledPayment> payments,
  ) => [
    for (final p in payments)
      {
        'due_date': InstallmentPaymentModel.isoDate(p.dueDate),
        'amount': p.amount,
      },
  ];

  /// Full row for the offline cache; round-trips through [InstallmentPlanModel.fromJson].
  Map<String, dynamic> toCacheJson() => {
    ...writeJson(toDraft(), id: id),
    'created_at': createdAt?.toIso8601String(),
    'products': productName == null ? null : {'name': productName},
    'installment_payments': [for (final p in payments) p.toCacheJson()],
  };

  /// This plan with [payment] swapped in.
  @override
  InstallmentPlanModel withPayment(InstallmentPayment payment) {
    final saved = InstallmentPaymentModel.from(payment);
    return InstallmentPlanModel(
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
      payments: [for (final p in payments) p.id == saved.id ? saved : p],
    );
  }
}
