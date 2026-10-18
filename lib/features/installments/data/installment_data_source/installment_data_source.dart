import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/service/receipt_ai_client.dart';
import '../../../../core/util/pii_masker.dart';
import '../../domain/entities/scanned_installment.dart';
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

  /// Reads a plan with the AI from a screenshot or a contract's first page
  /// ([imagePath], with the PDF's own [pdfText] when there is one) and/or
  /// pasted [text].
  Future<ScannedInstallment> extractInstallment({
    String? imagePath,
    String? pdfText,
    String? text,
  });
}

class InstallmentDataSourceImpl implements InstallmentDataSource {
  final SupabaseClient _client;
  final ReceiptAiClient _ai;
  InstallmentDataSourceImpl(this._client, {ReceiptAiClient? ai})
    : _ai = ai ?? ReceiptAiClient(_client);

  /// Error code passed up as the failure message when the AI found no plan
  /// in the contract, screenshot or text (see userFacingError).
  static const unreadableInstallment = 'unreadable_installment';

  /// The screenshot is only needed while the AI reads it.
  static const _screenshotUrlExpiry = Duration(minutes: 10);

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

  @override
  Future<ScannedInstallment> extractInstallment({
    String? imagePath,
    String? pdfText,
    String? text,
  }) async {
    UploadedReceipt? upload;
    try {
      if (imagePath != null) {
        upload = await _ai.upload(imagePath, expiry: _screenshotUrlExpiry);
      }
      // Full card numbers and email addresses never leave the device.
      String? scrub(String? value) =>
          value == null ? null : PiiMasker.scrub(PiiMasker.maskCardNumbers(value));
      final data = await _ai.extract({
        'mode': 'installment',
        'imageUrl': ?upload?.signedUrl,
        'pdfText': ?scrub(pdfText),
        'text': ?scrub(text),
      });
      double? number(String key) => (data[key] as num?)?.toDouble();
      return ScannedInstallment(
        title: data['title'] as String?,
        provider: data['provider'] as String?,
        totalPrice: number('totalPrice'),
        downPayment: number('downPayment'),
        installmentAmount: number('installmentAmount'),
        installmentsCount: (data['installmentsCount'] as num?)?.toInt(),
        firstDueDate: data['firstDueDate'] is String ? DateTime.tryParse(data['firstDueDate'] as String) : null,
        dueDayOfMonth: (data['dueDayOfMonth'] as num?)?.toInt(),
        interestOrFees: number('interestOrFees'),
        currency: data['currency'] as String?,
        confidence: number('confidence') ?? 0,
      );
    } on ServerException catch (e) {
      if (e.message == ReceiptAiClient.unreadable) {
        throw ServerException(unreadableInstallment);
      }
      rethrow;
    } catch (e) {
      throw ServerException('Installment scan failed: $e');
    } finally {
      // Not kept: plans don't store the screenshot or contract.
      if (upload != null) await _ai.delete(upload.path);
    }
  }
}
