import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/installment_payment_model.dart';
import '../models/installment_plan_model.dart';

abstract class InstallmentDataSource {
  Future<List<InstallmentPlanModel>> getPlans();

  /// Calls save_installment_plan and returns the saved plan with its
  /// payments.
  Future<InstallmentPlanModel> savePlan(
    Map<String, dynamic> planJson,
    List<Map<String, dynamic>> paymentsJson,
  );

  Future<void> deletePlan(String id);

  Future<InstallmentPaymentModel> setPaymentPaid(
    String paymentId,
    DateTime? paidAt,
  );
}

class InstallmentDataSourceImpl implements InstallmentDataSource {
  final SupabaseClient _client;
  InstallmentDataSourceImpl(this._client);

  static const _table = 'installment_plans';
  static const _paymentsTable = 'installment_payments';
  static const _saveFunction = 'save_installment_plan';

  @override
  Future<List<InstallmentPlanModel>> getPlans() async {
    try {
      final rows = await _client
          .from(_table)
          .select(InstallmentPlanModel.selectColumns)
          .order('created_at', ascending: false);
      return (rows as List)
          .map(
            (row) => InstallmentPlanModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to load installment plans: $e');
    }
  }

  @override
  Future<InstallmentPlanModel> savePlan(
    Map<String, dynamic> planJson,
    List<Map<String, dynamic>> paymentsJson,
  ) async {
    try {
      // Plan and payments are written in one transaction; the function
      // returns the plan row alone, so read it back with its payments.
      final saved = await _client.rpc(
        _saveFunction,
        params: {'p_plan': planJson, 'p_payments': paymentsJson},
      );
      final row = await _client
          .from(_table)
          .select(InstallmentPlanModel.selectColumns)
          .eq('id', (saved as Map<String, dynamic>)['id'] as String)
          .single();
      return InstallmentPlanModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to save installment plan: $e');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      // Its payments go with it (on delete cascade).
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete installment plan: $e');
    }
  }

  @override
  Future<InstallmentPaymentModel> setPaymentPaid(
    String paymentId,
    DateTime? paidAt,
  ) async {
    try {
      final row = await _client
          .from(_paymentsTable)
          .update(InstallmentPaymentModel.paidJson(paidAt))
          .eq('id', paymentId)
          .select()
          .single();
      return InstallmentPaymentModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to update the installment payment: $e');
    }
  }
}
