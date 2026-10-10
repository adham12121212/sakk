import 'package:dartz/dartz.dart';
import 'package:sakk/core/error/Failure.dart';
import 'package:sakk/features/products/domain/enties/product_entity.dart';

import '../../../category/domain/entities/product_category.dart';
import '../enties/scanned_receipt.dart';
import '../enties/warranty_claim.dart';

abstract class ProductRepo {


  Future<Either<Failure, ScannedReceiptData>> scanReceipt({
    required String imagePath,
    String? pdfText,
  });

  /// Deletes a scanned receipt photo the user didn't save. Best effort.
  Future<void> discardReceiptImage(String path);

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
  });

  Future<Either<Failure, List<ProductEntity>>> getProducts();

  Future<Either<Failure, ScannedReceiptData>> getTotalPrice();

  Future<Either<Failure, void>> deleteProduct(String id);

  /// Removes products saved on this device for offline use.
  Future<void> clearCachedProducts();

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
  });

  // Extra warranties and claims. Callers reload the product list afterwards;
  // products arrive with both embedded.
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
}