import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../enties/scanned_receipt.dart';
import '../product_repo/product_repo.dart';

abstract class ScanReceiptUseCase {
  Future<Either<Failure, ScannedReceiptData>> call({required String imagePath});
}

class ScanReceiptUseCaseImpl implements ScanReceiptUseCase {
  final ProductRepo _repository;
  ScanReceiptUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, ScannedReceiptData>> call({required String imagePath}) {
    return _repository.scanReceipt(imagePath: imagePath);
  }
}