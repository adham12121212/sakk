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
import '../models/product_model.dart';
import '../product_data_source/product_data_source.dart';

class ProductRepoImpl implements ProductRepo {
  final ProductDataSource _dataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  ProductRepoImpl(this._dataSource, this._networkInfo, this._logger);

  @override
  Future<Either<Failure, ScannedReceiptData>> scanReceipt({
    required String imagePath,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await _dataSource.scanReceipt(imagePath: imagePath);
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
      );

      final saved = await _dataSource.addProduct(
        model.toInsertJson(userId: userId),
      );
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
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final products = await _dataSource.getProducts();
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
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during getProducts',
        error: e,
        stackTrace: st,
      );
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
          currency: currency
      );
      final updated = await _dataSource.updateProduct(id, model.toUpdateJson());
      return Right(updated);
    }on ServerException catch(e,st){
      _logger.error('Server error during updateProduct', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    }catch(e,st){
      _logger.error('Unexpected error during updateProduct', error: e, stackTrace: st);
      return Left(ServerFailure(e.toString()));
    }
  }
}