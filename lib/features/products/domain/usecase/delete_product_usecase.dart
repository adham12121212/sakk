
import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../product_repo/product_repo.dart';

abstract class DeleteProductUseCase {
  Future<Either<Failure, void>> call(String id);
}


class DeleteProductUsecaseImpl implements DeleteProductUseCase{
  final ProductRepo _repository;
  DeleteProductUsecaseImpl(this._repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return  _repository.deleteProduct(id);
  }

}



