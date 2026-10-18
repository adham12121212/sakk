import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/scanned_installment.dart';
import '../installment_repo/installment_repo.dart';

abstract class ExtractInstallmentUseCase {
  /// Reads a plan from a screenshot or contract page ([imagePath], with the
  /// PDF's [pdfText]) and/or pasted [text].
  Future<Either<Failure, ScannedInstallment>> call({
    String? imagePath,
    String? pdfText,
    String? text,
  });
}

class ExtractInstallmentUseCaseImpl implements ExtractInstallmentUseCase {
  final InstallmentRepo _repository;
  ExtractInstallmentUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, ScannedInstallment>> call({
    String? imagePath,
    String? pdfText,
    String? text,
  }) {
    return _repository.extractInstallment(
      imagePath: imagePath,
      pdfText: pdfText,
      text: text,
    );
  }
}
