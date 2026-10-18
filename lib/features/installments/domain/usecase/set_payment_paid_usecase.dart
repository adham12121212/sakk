import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/installment_payment.dart';
import '../installment_repo/installment_repo.dart';

abstract class SetPaymentPaidUseCase {
  /// Marks a payment paid at [paidAt] (now by default), or unpaid again when
  /// [paid] is false.
  Future<Either<Failure, InstallmentPayment>> call(
    String paymentId, {
    required bool paid,
    DateTime? paidAt,
  });
}

class SetPaymentPaidUseCaseImpl implements SetPaymentPaidUseCase {
  final InstallmentRepo _repository;
  SetPaymentPaidUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, InstallmentPayment>> call(
    String paymentId, {
    required bool paid,
    DateTime? paidAt,
  }) {
    return _repository.setPaymentPaid(
      paymentId,
      paidAt: paid ? (paidAt ?? DateTime.now()) : null,
    );
  }
}
