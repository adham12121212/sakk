import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../category/domain/entities/product_category.dart';
import '../entities/product_entity.dart';
import '../product_repo/product_repo.dart';

abstract class AddProductUseCase {
  Future<Either<Failure, ProductEntity>> call({
    required String name,
    String? brand,
    double? price,
    required DateTime purchaseDate,
    required int warrantyMonths,
    String? imageUrl,
    String? receiptUrl,
    String? store,
    String? notes,
    required WarrantyStatus status,
    required ProductCategory category,
    required String currency,
    int? returnDays,
    String? serialNumber,
    String? invoiceNumber,
  });
}

class AddProductUseCaseImpl implements AddProductUseCase {
  final ProductRepo _repository;
  AddProductUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, ProductEntity>> call({
    required String name,
    String? brand,
    double? price,
    required DateTime purchaseDate,
    required int warrantyMonths,
    String? imageUrl,
    String? receiptUrl,
    String? store,
    String? notes,
    required WarrantyStatus status,
    required ProductCategory category,
    required String currency,
    int? returnDays,
    String? serialNumber,
    String? invoiceNumber,
  }) {
    return _repository.addProduct(
      name: name,
      brand: brand,
      price: price,
      purchaseDate: purchaseDate,
      warrantyMonths: warrantyMonths,
      imageUrl: imageUrl,
      receiptUrl: receiptUrl,
      store: store,
      notes: notes,
      status: status,
      category: category,
      currency: currency,
      returnDays: returnDays,
      serialNumber: serialNumber,
      invoiceNumber: invoiceNumber,
    );
  }
}