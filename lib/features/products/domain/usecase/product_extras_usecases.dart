import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../enties/product_document.dart';
import '../enties/warranty_claim.dart';
import '../product_repo/product_repo.dart';

/// Extra warranties and warranty claims on a product.
abstract class ProductExtrasUseCase {
  Future<Either<Failure, void>> addExtraWarranty({
    required String productId,
    required String provider,
    required DateTime startDate,
    required int months,
  });

  Future<Either<Failure, void>> deleteExtraWarranty(String id);

  Future<Either<Failure, void>> addClaim({required String productId, required String issue});

  Future<Either<Failure, void>> updateClaimStatus(String id, ClaimStatus status);

  Future<Either<Failure, void>> deleteClaim(String id);

  Future<Either<Failure, void>> addDocument({
    required String productId,
    required DocumentKind kind,
    required String filePath,
  });

  Future<Either<Failure, void>> deleteDocument(ProductDocument document);
}

class ProductExtrasUseCaseImpl implements ProductExtrasUseCase {
  ProductExtrasUseCaseImpl(this._repository);

  final ProductRepo _repository;

  @override
  Future<Either<Failure, void>> addExtraWarranty({
    required String productId,
    required String provider,
    required DateTime startDate,
    required int months,
  }) =>
      _repository.addExtraWarranty(
        productId: productId,
        provider: provider,
        startDate: startDate,
        months: months,
      );

  @override
  Future<Either<Failure, void>> deleteExtraWarranty(String id) => _repository.deleteExtraWarranty(id);

  @override
  Future<Either<Failure, void>> addClaim({required String productId, required String issue}) =>
      _repository.addClaim(productId: productId, issue: issue);

  @override
  Future<Either<Failure, void>> updateClaimStatus(String id, ClaimStatus status) =>
      _repository.updateClaimStatus(id, status);

  @override
  Future<Either<Failure, void>> deleteClaim(String id) => _repository.deleteClaim(id);

  @override
  Future<Either<Failure, void>> addDocument({
    required String productId,
    required DocumentKind kind,
    required String filePath,
  }) =>
      _repository.addDocument(productId: productId, kind: kind, filePath: filePath);

  @override
  Future<Either<Failure, void>> deleteDocument(ProductDocument document) => _repository.deleteDocument(document);
}
