import 'package:dartz/dartz.dart';
import 'package:sakk/features/products/domain/enties/product_entity.dart';

import '../../../../core/error/Failure.dart';
import '../../../category/domain/entities/product_category.dart';
import '../product_repo/product_repo.dart';

abstract class UpdateProductUseCase {
  Future<Either<Failure, ProductEntity>> call({
    required String id,
    required String name,
    String? brand,
    double? price,
    required String currency,
    required DateTime purchaseDate,
    required int warrantyMonths,
    String? imageUrl,
    String? receiptUrl,
    String? store,
    String? notes,
    required ProductCategory category,
  });
}

class UpdateProductUsecaseImpl implements UpdateProductUseCase {
  final ProductRepo _repository;
  UpdateProductUsecaseImpl(this._repository);

  @override
  Future<Either<Failure, ProductEntity>> call({
    required String id,
    required String name,
    String? brand,
    double? price,
    required String currency,
    required DateTime purchaseDate,
    required int warrantyMonths,
    String? imageUrl,
    String? receiptUrl,
    String? store,
    String? notes,
    required ProductCategory category,
  }) {

    return _repository.updateProduct(
        id: id,
        name: name,
        currency: currency,
        price: price,
        purchaseDate: purchaseDate,
        warrantyMonths: warrantyMonths,
        category: category,
        imageUrl: imageUrl,
        receiptUrl: receiptUrl,
        store: store,
        notes: notes,
    );
  }
}
