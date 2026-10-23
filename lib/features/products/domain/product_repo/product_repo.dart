import 'package:dartz/dartz.dart';
import 'package:sakk/core/service/receipt_ai_client.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';

import '../../../category/domain/entities/product_category.dart';
import '../entities/product_document.dart';
import '../entities/scanned_receipt.dart';
import '../entities/warranty_claim.dart';

abstract class ProductRepo {
  Future<Either<Failure, ScannedReceiptData>> scanReceipt({
    required String imagePath,
    String? pdfText,
  });

  /// A product the user described out loud (Sakk Pro).
  Future<Either<Failure, ScannedReceiptData>> scanVoice({
    required String audioPath,
  });

  /// Uploads a photo for a product added without a receipt photo.
  Future<Either<Failure, UploadedReceipt>> uploadReceiptPhoto({
    required String imagePath,
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

  Future<Either<Failure, void>> addClaim({
    required String productId,
    required String issue,
  });

  Future<Either<Failure, void>> updateClaimStatus(
    String id,
    ClaimStatus status,
  );

  Future<Either<Failure, void>> deleteClaim(String id);

  Future<Either<Failure, void>> addDocument({
    required String productId,
    required DocumentKind kind,
    required String filePath,
  });

  Future<Either<Failure, void>> deleteDocument(ProductDocument document);
}
