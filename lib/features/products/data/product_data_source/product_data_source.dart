import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exceptions.dart';
import '../../domain/enties/scanned_receipt.dart';
import '../models/product_model.dart';

abstract class ProductDataSource {

  Future<ScannedReceiptData> scanReceipt({required String imagePath});

  Future<ProductModel> addProduct(Map<String, dynamic> insertJson);

  Future<List<ProductModel>> getProducts();

  Future<void> deleteProduct(String id);

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> updateJson);

}

class ProductDataSourceImpl implements ProductDataSource {
  final SupabaseClient _client;
  ProductDataSourceImpl(this._client);

  static const _receiptsBucket = 'receipts';
  static const _extractFunctionName = 'extract-receipt';

  static const _signedUrlExpirySeconds = 60 * 60 * 24 * 365 * 5;

  @override
  Future<ScannedReceiptData> scanReceipt({required String imagePath}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('You must be signed in to scan a receipt');
      }

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from(_receiptsBucket).upload(fileName, File(imagePath));

      final signedUrl = await _client.storage
          .from(_receiptsBucket)
          .createSignedUrl(fileName, _signedUrlExpirySeconds);

      final response = await _client.functions.invoke(
        _extractFunctionName,
        body: {'imageUrl': signedUrl},
      );

      if (response.status != 200) {
        throw ServerException('Receipt scan failed (status ${response.status})');
      }

      final data = response.data as Map<String, dynamic>;

      return ScannedReceiptData(
        productName: data['productName'] as String?,
        brand: data['brand'] as String?,
        store: data['store_name'] as String?,
        price: (data['price'] as num?)?.toDouble(),
        purchaseDate: data['purchaseDate'] != null
            ? DateTime.tryParse(data['purchaseDate'] as String)
            : null,
        warrantyMonths: data['warrantyMonths'] as int?,
        receiptImageUrl: signedUrl,
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['imageUrl'] as String?,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Receipt scan failed: $e');
    }
  }

  @override
  Future<ProductModel> addProduct(Map<String, dynamic> insertJson) async {
    try {
      final row = await _client
          .from('products')
          .insert(insertJson)
          .select()
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
          .select()
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
      // NOTE: was querying 'product' (singular) — that table doesn't
      // exist, every other method here correctly uses 'products'. This
      // would have compiled fine but failed at runtime on every save.
      final row = await _client.from('products')
          .update(updateJson)
          .eq('id', id)
          .select()
          .single();
      return ProductModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to update product: $e');
    }
  }



}