import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../domain/entities/scanned_receipt.dart';
import '../models/product_model.dart';

abstract class ProductDataSource {

  Future<ScannedReceiptData> scanReceipt({required String imagePath, String? pdfText});

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

  /// Uploads a photo (or rendered PDF page) and attaches it to the product.
  Future<void> addDocument({required String productId, required String kind, required String filePath});

  Future<void> deleteDocument({required String id, required String path});
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
  static const pdfUnreadable = 'pdf_unreadable';

  @override
  Future<ScannedReceiptData> scanReceipt({required String imagePath, String? pdfText}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw ServerException('You must be signed in to scan a receipt');
      }

      // .png for rendered PDF pages, .jpg for photos; the upload's content
      // type follows the extension.
      final extension = imagePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _client.storage.from(_receiptsBucket).upload(fileName, File(imagePath));

      final Map<String, dynamic> data;
      final String signedUrl;
      try {
        signedUrl = await _client.storage
            .from(_receiptsBucket)
            .createSignedUrl(fileName, _signedUrlExpirySeconds);

        final response = await _client.functions.invoke(
          _extractFunctionName,
          body: {'imageUrl': signedUrl, 'pdfText': ?pdfText},
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
    final List<String> files;
    try {
      // Read the file paths first: deleting the product deletes its document
      // rows too (cascade), but not the files in storage.
      final row = await _client
          .from('products')
          .select('receipt_url, image_url, product_documents(file_path)')
          .eq('id', id)
          .maybeSingle();
      files = row == null
          ? const []
          : {
              for (final url in [row['receipt_url'], row['image_url']])
                if (url is String) receiptPathFromUrl(url),
              for (final d in (row['product_documents'] as List? ?? const []))
                (d as Map<String, dynamic>)['file_path'] as String?,
            }.whereType<String>().toList();
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete product: $e');
    }
    // After the row is gone, so a failed delete never leaves a product
    // without its photos. Best effort: deleteReceiptImage never throws.
    for (final path in files) {
      await deleteReceiptImage(path);
    }
  }

  /// Storage path of a signed receipts URL
  /// (`.../storage/v1/object/sign/receipts/<path>?token=...`), or null for
  /// any other URL.
  static String? receiptPathFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments ?? const [];
    final i = segments.indexOf('sign');
    if (i < 0 || i + 2 >= segments.length || segments[i + 1] != _receiptsBucket) return null;
    return segments.sublist(i + 2).join('/');
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
  Future<void> addDocument({required String productId, required String kind, required String filePath}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw ServerException('You must be signed in to add a document');
    final extension = filePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    // Own folder: the storage rules and the table's check both require it.
    final path = '$userId/documents/${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await _client.storage.from(_receiptsBucket).upload(path, File(filePath));
      final url = await _client.storage.from(_receiptsBucket).createSignedUrl(path, _signedUrlExpirySeconds);
      await _client.from('product_documents').insert({
        'product_id': productId,
        'kind': kind,
        'file_url': url,
        'file_path': path,
      });
    } catch (e) {
      await deleteReceiptImage(path); // don't leave an unattached file behind
      throw ServerException('Failed to add document: $e');
    }
  }

  @override
  Future<void> deleteDocument({required String id, required String path}) async {
    try {
      await _client.from('product_documents').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete document: $e');
    }
    await deleteReceiptImage(path);
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
