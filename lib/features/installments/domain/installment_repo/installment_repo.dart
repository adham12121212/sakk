import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/installment_payment.dart';
import '../entities/installment_plan.dart';
import '../entities/installment_plan_draft.dart';
import '../entities/scheduled_payment.dart';

abstract class InstallmentRepo {
  /// The signed-in user's plans with their payments.
  Future<Either<Failure, List<InstallmentPlan>>> getPlans();

  /// Adds a plan (no [id]) or updates [id], together with its [unpaid]
  /// installments. On an update, paid installments are kept and every
  /// unpaid one is replaced by [unpaid].
  Future<Either<Failure, InstallmentPlan>> savePlan({
    String? id,
    required InstallmentPlanDraft draft,
    required List<ScheduledPayment> unpaid,
  });

  /// Deletes the plan and its payments.
  Future<Either<Failure, void>> deletePlan(String id);

  /// Marks a payment paid at [paidAt], or unpaid again when it's null.
  Future<Either<Failure, InstallmentPayment>> setPaymentPaid(
    String paymentId, {
    DateTime? paidAt,
  });

  /// Removes the plans saved on this device for offline use.
  Future<void> clearCachedInstallments();
}
