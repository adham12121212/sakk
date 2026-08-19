import 'package:dartz/dartz.dart';
import 'package:sakk/core/error/Failure.dart';
import 'package:sakk/features/products/domain/enties/product_entity.dart';

import '../../../category/domain/entities/product_category.dart';
import '../enties/scanned_receipt.dart';

abstract class ProductRepo {


  Future<Either<Failure, ScannedReceiptData>> scanReceipt({
    required String imagePath,
  });

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
  });

  Future<Either<Failure, List<ProductEntity>>> getProducts();

  Future<Either<Failure, ScannedReceiptData>> getTotalPrice();

  Future<Either<Failure, void>> deleteProduct(String id);

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
  });

}