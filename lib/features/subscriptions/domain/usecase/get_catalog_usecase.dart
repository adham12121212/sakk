import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/catalog_service.dart';
import '../subscription_repo/subscription_repo.dart';

abstract class GetCatalogUseCase {
  Future<Either<Failure, List<CatalogService>>> call();
}

class GetCatalogUseCaseImpl implements GetCatalogUseCase {
  final SubscriptionRepo _repository;
  GetCatalogUseCaseImpl(this._repository);

  @override
  Future<Either<Failure, List<CatalogService>>> call() {
    return _repository.getCatalog();
  }
}
