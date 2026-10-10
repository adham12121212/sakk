import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exceptions.dart';
import '../../../../core/error/Failure.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/logger/app_logger.dart';

import '../../../category/domain/entities/product_category.dart';
import '../../domain/enties/product_entity.dart';
import '../../domain/enties/scanned_receipt.dart';
import '../../domain/product_repo/product_repo.dart';
import '../../domain/enties/warranty_claim.dart';
import '../models/product_model.dart';
import '../product_data_source/product_data_source.dart';
import '../product_data_source/product_local_data_source.dart';

class ProductRepoImpl implements ProductRepo {
  final ProductDataSource _dataSource;
  final ProductLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  ProductRepoImpl(this._dataSource, this._localDataSource, this._networkInfo, this._logger);

  /// The on-device copy as domain entities, or null if there is none.
  /// Cache problems are logged and treated as "no cache", never as a failure.
  Future<List<ProductEntity>?> _cachedProducts() async {
    try {
      final cached = await _localDataSource.getCachedProducts();
      return cached == null ? null : List<ProductEntity>.from(cached);
    } catch (e) {
      _logger.warning('Reading the offline product cache failed', data: {'error': '$e'});
      return null;
    }
  }

  /// Applies [change] to the cached list (if any), so an add/edit/delete made
  /// online is also reflected the next time the app is offline.
  Future<void> _updateCache(List<ProductModel> Function(List<ProductModel> current) change) async {
    try {
      final current = await _localDataSource.getCachedProducts();
      if (current == null) return;
      await _localDataSource.cacheProducts(change(current));
    } catch (e) {
      _logger.warning('Updating the offline product cache failed', data: {'error': '$e'});
    }
  }

  @override
  Future<void> clearCachedProducts() async {
    try {
      await _localDataSource.clearAll();
    } catch (e) {
      _logger.warning('Clearing the offline product cache failed', data: {'error': '$e'});
    }
  }

  @override
  Future<void> discardReceiptImage(String path) => _dataSource.deleteReceiptImage(path);

  @override
  Future<Either<Failure, ScannedReceiptData>> scanReceipt({
    required String imagePath,
    String? pdfText,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await _dataSource.scanReceipt(imagePath: imagePath, pdfText: pdfText);
      return Right(result);
    } on ServerException catch (e, st) {
      _logger.error(
        'Server error during scanReceipt',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during scanReceipt',
        error: e,
        stackTrace: st,
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> addProduct({
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
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return const Left(
          AuthFailure('You must be signed in to add a product'),
        );
      }

      final model = ProductModel(
        id: '',
        name: name,
        brand: brand,
        price: price,
        currency: currency,
        purchaseDate: purchaseDate,
        warrantyMonths: warrantyMonths,
        imageUrl: imageUrl,
        receiptUrl: receiptUrl,
        store: store,
        notes: notes,
        category: category,
        returnDays: returnDays,
        serialNumber: serialNumber,
        invoiceNumber: invoiceNumber,
      );

      final saved = await _dataSource.addProduct(
        model.toInsertJson(userId: userId),
      );
      await _updateCache((current) => [saved, ...current]);
      return Right(saved);
    } on ServerException catch (e, st) {
      _logger.error('Server error during addProduct', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during addProduct',
        error: e,
        stackTrace: st,
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    // Offline: serve the last list saved on this device, if there is one.
    if (!await _networkInfo.isConnected) {
      final cached = await _cachedProducts();
      return cached != null
          ? Right(cached)
          : const Left(NetworkFailure(NetworkFailure.noConnectionMessage));
    }
    try {
      final products = await _dataSource.getProducts();
      try {
        await _localDataSource.cacheProducts(products);
      } catch (e) {
        _logger.warning('Saving the offline product cache failed', data: {'error': '$e'});
      }
      // Explicitly re-wrap: `products` is a List<ProductModel> at runtime
      // (Dart's generics are reified), and since ProductModel extends
      // ProductEntity, `Right(products)` compiles fine via covariance —
      // but the list stays List<ProductModel> forever. Any later generic
      // call on it (e.g. firstWhere's orElse) then binds against
      // ProductModel instead of ProductEntity, breaking any caller that
      // passes a plain ProductEntity. Converting here keeps the domain
      // layer's contract (List<ProductEntity>) genuinely true at runtime.
      return Right<Failure, List<ProductEntity>>(List<ProductEntity>.from(products));
    } on ServerException catch (e, st) {
      _logger.error(
        'Server error during getProducts',
        error: e,
        stackTrace: st,
      );
      // A failed load still shows the last saved list, if any.
      final cached = await _cachedProducts();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during getProducts',
        error: e,
        stackTrace: st,
      );
      final cached = await _cachedProducts();
      if (cached != null) return Right(cached);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await _dataSource.deleteProduct(id);
      await _updateCache((current) => current.where((p) => p.id != id).toList());
      return const Right(null);
    } on ServerException catch (e, st) {
      _logger.error(
        'Server error during deleteProduct',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during deleteProduct',
        error: e,
        stackTrace: st,
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ScannedReceiptData>> getTotalPrice() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final products = await _dataSource.getProducts();
      final totalPrice = products.fold<double>(
        0.0,
            (sum, product) => sum + (product.price ?? 0.0),
      );
      return Right(ScannedReceiptData(price: totalPrice));
    } on ServerException catch (e, st) {
      _logger.error(
        'Server error during getTotalPrice',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Server error during getTotalPrice',
        error: e,
        stackTrace: st,
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct({
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
    int? returnDays,
    String? serialNumber,
    String? invoiceNumber,
  })  async{
    if(!await _networkInfo.isConnected){
      return const Left(NetworkFailure('No internet connection'));
    }
    try{
      final model = ProductModel(
          id: id,
          name: name,
          brand: brand,
          price: price,
          purchaseDate: purchaseDate,
          warrantyMonths: warrantyMonths,
          imageUrl: imageUrl,
          receiptUrl: receiptUrl,
          store: store,
          notes: notes,
          category: category,
          currency: currency,
          returnDays: returnDays,
          serialNumber: serialNumber,
          invoiceNumber: invoiceNumber,
      );
      final updated = await _dataSource.updateProduct(id, model.toUpdateJson());
      await _updateCache((current) => [for (final p in current) p.id == id ? updated : p]);
      return Right(updated);
    }on ServerException catch(e,st){
      _logger.error('Server error during updateProduct', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    }catch(e,st){
      _logger.error('Unexpected error during updateProduct', error: e, stackTrace: st);
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Runs a write that needs the network, mapping errors like the methods above.
  Future<Either<Failure, void>> _write(String action, Future<void> Function() run) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(NetworkFailure.noConnectionMessage));
    }
    try {
      await run();
      return const Right(null);
    } on ServerException catch (e, st) {
      _logger.error('Server error during $action', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Unexpected error during $action', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addExtraWarranty({
    required String productId,
    required String provider,
    required DateTime startDate,
    required int months,
  }) =>
      _write('addExtraWarranty', () => _dataSource.addExtraWarranty(
            productId: productId,
            provider: provider,
            startDate: startDate,
            months: months,
          ));

  @override
  Future<Either<Failure, void>> deleteExtraWarranty(String id) =>
      _write('deleteExtraWarranty', () => _dataSource.deleteExtraWarranty(id));

  @override
  Future<Either<Failure, void>> addClaim({required String productId, required String issue}) =>
      _write('addClaim', () => _dataSource.addClaim(productId: productId, issue: issue));

  @override
  Future<Either<Failure, void>> updateClaimStatus(String id, ClaimStatus status) =>
      _write('updateClaimStatus', () => _dataSource.updateClaimStatus(id, status.dbValue));

  @override
  Future<Either<Failure, void>> deleteClaim(String id) =>
      _write('deleteClaim', () => _dataSource.deleteClaim(id));
}
