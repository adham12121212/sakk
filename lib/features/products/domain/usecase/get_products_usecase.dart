import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../enties/product_entity.dart';
import '../product_repo/product_repo.dart';


abstract class GetProductsUseCase {
  Future<Either<Failure, List<ProductEntity>>> call();
}

class GetProductsUseCaseImpl implements GetProductsUseCase {
  final ProductRepo _repository;
  GetProductsUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call() {
    return _repository.getProducts();
  }
}