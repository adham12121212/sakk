import '../product_repo/product_repo.dart';

abstract class ClearCachedProductsUseCase {
  Future<void> call();
}

class ClearCachedProductsUseCaseImpl implements ClearCachedProductsUseCase {
  final ProductRepo _productRepo;
  ClearCachedProductsUseCaseImpl(this._productRepo);

  @override
  Future<void> call() => _productRepo.clearCachedProducts();
}
