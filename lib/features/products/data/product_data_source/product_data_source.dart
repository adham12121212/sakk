import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exceptions.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../domain/enties/scanned_receipt.dart';
import '../models/product_model.dart';

abstract class ProductDataSource {

  Future<ScannedReceiptData> scanReceipt({required String imagePath});

  /// Deletes an uploaded receipt photo that ended up not being saved.
  Future<void> deleteReceiptImage(String path);

  Future<ProductModel> addProduct(Map<String, dynamic> insertJson);

  Future<List<ProductModel>> getProducts();

  Future<void> deleteProduct(String id);

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> updateJson);

  Future<void> addExtraWarranty({
    required String productId,
    required String provider,
    required DateTime startDate,
    required int months,
  });

  Future<void> deleteExtraWarranty(String id);

  Future<void> addClaim({required String productId, required String issue});

  Future<void> updateClaimStatus(String id, String status);

  Future<void> deleteClaim(String id);
}

class ProductDataSourceImpl implements ProductDataSource {
  final SupabaseClient _client;
  ProductDataSourceImpl(this._client);

  static const _receiptsBucket = 'receipts';
  static const _extractFunctionName = 'extract-receipt';

  static const _signedUrlExpirySeconds = 60 * 60 * 24 * 365 * 5;

  /// Error codes the extract-receipt function returns, passed up as the
  /// failure message so the UI can explain them (see userFacingError).
  static const unreadableReceipt = 'unreadable_receipt';
  static const aiBusy = 'ai_busy';

  @override
  Future<ScannedReceiptData> scanReceipt({required String imagePath}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('You must be signed in to scan a receipt');
      }

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from(_receiptsBucket).upload(fileName, File(imagePath));

      final Map<String, dynamic> data;
      final String signedUrl;
      try {
        signedUrl = await _client.storage
            .from(_receiptsBucket)
            .createSignedUrl(fileName, _signedUrlExpirySeconds);

        final response = await _client.functions.invoke(
          _extractFunctionName,
          body: {'imageUrl': signedUrl},
        );
        data = response.data as Map<String, dynamic>;
      } catch (e) {
        // The scan failed, so nothing will reference the photo: don't keep it.
        await deleteReceiptImage(fileName);
        if (e is FunctionException) {
          if (e.status == 422) throw ServerException(unreadableReceipt);
          if (e.status == 503) throw ServerException(aiBusy);
        }
        rethrow;
      }

      return ScannedReceiptData(
        productName: data['productName'] as String?,
        brand: data['brand'] as String?,
        store: data['store_name'] as String?,
        price: (data['price'] as num?)?.toDouble(),
        purchaseDate: data['purchaseDate'] != null
            ? DateTime.tryParse(data['purchaseDate'] as String)
            : null,
        warrantyMonths: data['warrantyMonths'] as int?,
        serialNumber: data['serialNumber'] as String?,
        invoiceNumber: data['invoiceNumber'] as String?,
        foreignPrice: (data['foreignPrice'] as num?)?.toDouble(),
        foreignCurrency: data['foreignCurrency'] as String?,
        receiptPath: fileName,
        receiptImageUrl: signedUrl,
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['imageUrl'] as String?,
        // The `extract-receipt` edge function already classifies the
        // product into one of ProductCategory's values (see its
        // ALLOWED_CATEGORIES list) — this was previously never read here,
        // so every scanned product silently fell back to "Other"
        // regardless of what the AI detected. `ProductCategoryX.fromName`
        // already defaults unknown/null values to `other`, matching the
        // edge function's own fallback behavior.
        category: ProductCategoryX.fromName(data['category'] as String?),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Receipt scan failed: $e');
    }
  }

  @override
  Future<void> deleteReceiptImage(String path) async {
    try {
      await _client.storage.from(_receiptsBucket).remove([path]);
    } catch (_) {
      // Best effort: a leftover photo is harmless, so never fail the flow.
    }
  }

  @override
  Future<ProductModel> addProduct(Map<String, dynamic> insertJson) async {
    try {
      final row = await _client
          .from('products')
          .insert(insertJson)
          .select(ProductModel.selectColumns)
          .single();
      return ProductModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to save product: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final rows = await _client
          .from('products')
          .select(ProductModel.selectColumns)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => ProductModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to load products: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete product: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> updateJson) async{
    try{
      final row = await _client.from('products')
          .update(updateJson)
          .eq('id', id)
          .select(ProductModel.selectColumns)
          .single();
      return ProductModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to update product: $e');
    }
  }

  // user_id defaults to auth.uid() in the database, and RLS only accepts rows
  // for products the signed-in user owns.
  @override
  Future<void> addExtraWarranty({
    required String productId,
    required String provider,
    required DateTime startDate,
    required int months,
  }) async {
    try {
      await _client.from('product_warranties').insert({
        'product_id': productId,
        'provider': provider,
        'start_date': startDate.toIso8601String().split('T').first,
        'months': months,
      });
    } catch (e) {
      throw ServerException('Failed to add warranty: $e');
    }
  }

  @override
  Future<void> deleteExtraWarranty(String id) async {
    try {
      await _client.from('product_warranties').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete warranty: $e');
    }
  }

  @override
  Future<void> addClaim({required String productId, required String issue}) async {
    try {
      await _client.from('warranty_claims').insert({'product_id': productId, 'issue': issue});
    } catch (e) {
      throw ServerException('Failed to save claim: $e');
    }
  }

  @override
  Future<void> updateClaimStatus(String id, String status) async {
    try {
      await _client.from('warranty_claims').update({'status': status}).eq('id', id);
    } catch (e) {
      throw ServerException('Failed to update claim: $e');
    }
  }

  @override
  Future<void> deleteClaim(String id) async {
    try {
      await _client.from('warranty_claims').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete claim: $e');
    }
  }



}
