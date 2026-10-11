import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/scanned_receipt.dart';
import '../product_repo/product_repo.dart';

abstract class ScanReceiptUseCase {
  /// [pdfText] is the text of a PDF invoice, when the image is a rendered PDF page.
  Future<Either<Failure, ScannedReceiptData>> call({required String imagePath, String? pdfText});

  /// Deletes the uploaded photo of a scan the user didn't save.
  Future<void> discard(String receiptPath);
}

class ScanReceiptUseCaseImpl implements ScanReceiptUseCase {
  final ProductRepo _repository;
  ScanReceiptUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, ScannedReceiptData>> call({required String imagePath, String? pdfText}) {
    return _repository.scanReceipt(imagePath: imagePath, pdfText: pdfText);
  }

  @override
  Future<void> discard(String receiptPath) => _repository.discardReceiptImage(receiptPath);
}