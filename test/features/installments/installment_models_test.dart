import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/installments/data/models/installment_payment_model.dart';
import 'package:sakk/features/installments/data/models/installment_plan_model.dart';
import 'package:sakk/features/installments/domain/entities/installment_payment.dart';
import 'package:sakk/features/installments/domain/entities/scheduled_payment.dart';

/// An installment_plans row as Supabase returns it with InstallmentPlanModel.selectColumns.
Map<String, dynamic> planRow({String id = 'pl1', String? productName = 'iPhone 16'}) => {
      'id': id,
      'user_id': 'u1',
      'product_id': productName == null ? null : 'prod1',
      'title': 'iPhone',
      'provider': 'Valu',
      'currency': 'EGP',
      'total_price': 30000,
      'down_payment': 6000.5,
      'installment_amount': 2000,
      'installments_count': 2,
      'start_date': '2026-11-30',
      'due_day_of_month': 31,
      'interest_or_fees': null,
      'notes': null,
      'status': 'active',
      'created_at': '2026-10-18T10:00:00Z',
      'updated_at': '2026-10-18T10:00:00Z',
      'products': productName == null ? null : {'name': productName},
      // Out of order on purpose: PostgREST doesn't promise an order.
      'installment_payments': [
        {'id': 'py2', 'plan_id': id, 'user_id': 'u1', 'due_date': '2026-12-31', 'amount': 2000, 'paid_at': null, 'status': 'pending', 'created_at': '2026-10-18T10:00:00Z'},
        {'id': 'py1', 'plan_id': id, 'user_id': 'u1', 'due_date': '2026-11-30', 'amount': 2000, 'paid_at': '2026-11-29T08:00:00Z', 'status': 'paid', 'created_at': '2026-10-18T10:00:00Z'},
      ],
    };

void main() {
  test('reads a plan with its payments in due order and its product name', () {
    final p = InstallmentPlanModel.fromJson(planRow());
    expect(p.name, 'iPhone 16');
    expect(p.terms.downPayment, 6000.5);
    expect(p.terms.dueDayOfMonth, 31);
    expect(p.terms.startDate, DateTime(2026, 11, 30));
    expect(p.payments.map((x) => x.id), ['py1', 'py2']);
    expect(p.payments.first.isPaid, isTrue);
    expect(p.isCancelled, isFalse);
  });

  test('a deleted product leaves the title', () {
    expect(InstallmentPlanModel.fromJson(planRow(productName: null)).name, 'iPhone');
  });

  test('round-trips through the offline cache', () {
    final p = InstallmentPlanModel.fromJson(planRow());
    final back = InstallmentPlanModel.fromJson(jsonDecode(jsonEncode(p.toCacheJson())) as Map<String, dynamic>);
    expect(back, p);
  });

  test('writes the plan without an id when new, with dates only', () {
    final p = InstallmentPlanModel.fromJson(planRow());
    final json = InstallmentPlanModel.writeJson(p.toDraft());
    expect(json.containsKey('id'), isFalse);
    expect(json['start_date'], '2026-11-30');
    expect(json['status'], 'active');
    expect(InstallmentPlanModel.writeJson(p.toDraft(), id: 'pl1')['id'], 'pl1');
    expect(
      InstallmentPlanModel.paymentsJson([ScheduledPayment(dueDate: DateTime(2027, 2, 28, 15), amount: 99.5)]),
      [{'due_date': '2027-02-28', 'amount': 99.5}],
    );
  });

  test('paid and unpaid keep status and paid_at in step', () {
    expect(InstallmentPaymentModel.paidJson(null), {'status': 'pending', 'paid_at': null});
    final paid = InstallmentPaymentModel.paidJson(DateTime.utc(2026, 11, 29, 8));
    expect(paid, {'status': 'paid', 'paid_at': '2026-11-29T08:00:00.000Z'});
  });

  test('swapping in a plain payment keeps the plan a model', () {
    final p = InstallmentPlanModel.fromJson(planRow());
    final updated = p.withPayment(InstallmentPayment(id: 'py2', planId: 'pl1', dueDate: DateTime(2026, 12, 31), amount: 2000, paidAt: DateTime(2026, 12, 30)));
    expect(updated.isCompleted, isTrue);
    expect(updated.toCacheJson()['installment_payments'], hasLength(2));
  });
}
