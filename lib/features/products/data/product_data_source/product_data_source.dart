import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/service/receipt_ai_client.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../domain/entities/scanned_receipt.dart';
import '../models/product_model.dart';
import '../../../pro/domain/pro_limit.dart';

abstract class ProductDataSource {
  Future<ScannedReceiptData> scanReceipt({
    required String imagePath,
    String? pdfText,
  });

  /// A product the user described out loud (Sakk Pro), from the recording
  /// at [audioPath]. There's no receipt photo.
  Future<ScannedReceiptData> scanVoice({required String audioPath});

  /// Uploads a photo the user added to a product with no receipt photo yet
  /// (added by voice or by hand). It becomes the product's receipt image.
  Future<UploadedReceipt> uploadReceiptPhoto({required String imagePath});

  /// Deletes an uploaded receipt photo that ended up not being saved.
  Future<void> deleteReceiptImage(String path);

  Future<ProductModel> addProduct(Map<String, dynamic> insertJson);

  Future<List<ProductModel>> getProducts();

  Future<void> deleteProduct(String id);

  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> updateJson,
  );

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
  Future<void> addDocument({
    required String productId,
    required String kind,
    required String filePath,
  });

  Future<void> deleteDocument({required String id, required String path});
}

class ProductDataSourceImpl implements ProductDataSource {
  final SupabaseClient _client;
  final ReceiptAiClient _ai;
  ProductDataSourceImpl(this._client, {ReceiptAiClient? ai})
    : _ai = ai ?? ReceiptAiClient(_client);

  static const _receiptsBucket = ReceiptAiClient.bucket;

  /// Receipts and documents are stored as paths and signed each time
  /// products load, so no long-lived link sits in the database. Long enough
  /// for a link shared in a warranty claim or the CSV export to be opened.
  static const _signedUrlExpiry = Duration(days: 7);

  /// The photo only has to reach the AI and the review screen; the product
  /// keeps its path.
  static const _scanUrlExpiry = Duration(hours: 1);

  /// Error codes the extract-receipt function returns, passed up as the
  /// failure message so the UI can explain them (see userFacingError).
  static const unreadableReceipt = ReceiptAiClient.unreadable;
  static const aiBusy = ReceiptAiClient.aiBusy;
  static const pdfUnreadable = 'pdf_unreadable';

  /// A recording with nothing a product could be made from (silence, noise,
  /// or no product details said).
  static const voiceUnheard = 'voice_unheard';

  @override
  Future<ScannedReceiptData> scanReceipt({
    required String imagePath,
    String? pdfText,
  }) async {
    try {
      final upload = await _ai.upload(imagePath, expiry: _scanUrlExpiry);

      final Map<String, dynamic> data;
      try {
        data = await _ai.extract({
          'imageUrl': upload.signedUrl,
          'pdfText': ?pdfText,
        });
      } catch (_) {
        // The scan failed, so nothing will reference the photo: don't keep it.
        await _ai.delete(upload.path);
        rethrow;
      }

      return _scannedFrom(
        data,
      ).copyWith(receiptPath: upload.path, receiptImageUrl: upload.signedUrl);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Receipt scan failed: $e');
    }
  }

  @override
  Future<ScannedReceiptData> scanVoice({required String audioPath}) async {
    try {
      final upload = await _ai.upload(audioPath, expiry: _scanUrlExpiry);
      final Map<String, dynamic> data;
      try {
        data = await _ai.extract({
          'mode': 'voice',
          'audioUrl': upload.signedUrl,
        });
      } on ServerException catch (e) {
        // "Unreadable" here means nothing was heard, not a blurry photo.
        if (e.message == unreadableReceipt) {
          throw ServerException(voiceUnheard);
        }
        rethrow;
      } finally {
        // Only needed to transcribe; the product doesn't keep it.
        await _ai.delete(upload.path);
      }
      return _scannedFrom(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Voice add failed: $e');
    }
  }

  @override
  Future<UploadedReceipt> uploadReceiptPhoto({
    required String imagePath,
  }) async {
    try {
      return await _ai.upload(imagePath, expiry: _scanUrlExpiry);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Photo upload failed: $e');
    }
  }

  /// The extract-receipt function's product fields (receipt or voice).
  static ScannedReceiptData _scannedFrom(Map<String, dynamic> data) {
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
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String?,
      transcript: data['transcript'] as String?,
      // The function returns one of ProductCategory's values; fromName
      // falls back to `other` like the function does.
      category: ProductCategoryX.fromName(data['category'] as String?),
    );
  }

  @override
  Future<void> deleteReceiptImage(String path) => _ai.delete(path);

  @override
  Future<ProductModel> addProduct(Map<String, dynamic> insertJson) async {
    try {
      final row = await _client
          .from('products')
          .insert(withStoredPaths(insertJson))
          .select(ProductModel.selectColumns)
          .single();
      ProLimit.notifyUsageChanged();
      return ProductModel.fromJson((await _withSignedUrls([row])).single);
    } catch (e) {
      throw ProLimit.exceptionFor(e, 'Failed to save product: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final rows = await _client
          .from('products')
          .select(ProductModel.selectColumns)
          .order('created_at', ascending: false);
      final signed = await _withSignedUrls(
        (rows as List).cast<Map<String, dynamic>>(),
      );
      return signed.map(ProductModel.fromJson).toList();
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
      ProLimit.notifyUsageChanged();
    } catch (e) {
      throw ServerException('Failed to delete product: $e');
    }
    // After the row is gone, so a failed delete never leaves a product
    // without its photos. Best effort: deleteReceiptImage never throws.
    for (final path in files) {
      await deleteReceiptImage(path);
    }
  }

  /// Storage path of a receipts file: [url] is either the path itself
  /// (`<user id>/<file>`, how it's stored now) or a signed receipts URL
  /// (`.../storage/v1/object/sign/receipts/<path>?token=...`, how older rows
  /// and the app's own lists hold it). Null for any other value.
  static String? receiptPathFromUrl(String url) {
    if (_storedPath.hasMatch(url)) return url;
    final segments = Uri.tryParse(url)?.pathSegments ?? const [];
    final i = segments.indexOf('sign');
    if (i < 0 ||
        i + 2 >= segments.length ||
        segments[i + 1] != _receiptsBucket) {
      return null;
    }
    return segments.sublist(i + 2).join('/');
  }

  static final _storedPath = RegExp(r'^[0-9a-fA-F-]{36}/[^\s?#:]+$');

  /// [json] with any receipts link in it replaced by its path, so a signed
  /// URL the app was showing is never written back.
  @visibleForTesting
  static Map<String, dynamic> withStoredPaths(Map<String, dynamic> json) {
    return {
      for (final MapEntry(:key, :value) in json.entries)
        key: (key == 'receipt_url' || key == 'image_url') && value is String
            ? receiptPathFromUrl(value) ?? value
            : value,
    };
  }

  /// [rows] with every receipts path (receipt, image, documents) replaced by
  /// a fresh signed URL, in one request. A file that can't be signed keeps
  /// its stored value, which shows as a missing image.
  Future<List<Map<String, dynamic>>> _withSignedUrls(
    List<Map<String, dynamic>> rows,
  ) async {
    String? pathOf(Object? value) =>
        value is String ? receiptPathFromUrl(value) : null;
    List<Map<String, dynamic>> documentsOf(Map<String, dynamic> row) =>
        (row['product_documents'] as List? ?? const [])
            .cast<Map<String, dynamic>>();

    final paths = {
      for (final row in rows) ...[
        ?pathOf(row['receipt_url']),
        ?pathOf(row['image_url']),
        for (final d in documentsOf(row)) ?pathOf(d['file_path']),
      ],
    };
    if (paths.isEmpty) return rows;

    final Map<String, String> urls;
    try {
      final results = await _client.storage
          .from(_receiptsBucket)
          .createSignedUrlsResult(paths.toList(), _signedUrlExpiry.inSeconds);
      urls = {
        for (final r in results)
          if (r is SignedUrlSuccess) r.path: r.signedUrl,
      };
    } catch (_) {
      // Products still load; only their images are missing.
      return rows;
    }

    String? signed(Object? value) => urls[pathOf(value)] ?? value as String?;
    return [
      for (final row in rows)
        {
          ...row,
          'receipt_url': signed(row['receipt_url']),
          'image_url': signed(row['image_url']),
          if (row.containsKey('product_documents'))
            'product_documents': [
              for (final d in documentsOf(row))
                {...d, 'file_url': signed(d['file_path'])},
            ],
        },
    ];
  }

  @override
  Future<ProductModel> updateProduct(
    String id,
    Map<String, dynamic> updateJson,
  ) async {
    try {
      final row = await _client
          .from('products')
          .update(withStoredPaths(updateJson))
          .eq('id', id)
          .select(ProductModel.selectColumns)
          .single();
      return ProductModel.fromJson((await _withSignedUrls([row])).single);
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
  Future<void> addClaim({
    required String productId,
    required String issue,
  }) async {
    try {
      await _client.from('warranty_claims').insert({
        'product_id': productId,
        'issue': issue,
      });
    } catch (e) {
      throw ServerException('Failed to save claim: $e');
    }
  }

  @override
  Future<void> updateClaimStatus(String id, String status) async {
    try {
      await _client
          .from('warranty_claims')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to update claim: $e');
    }
  }

  @override
  Future<void> addDocument({
    required String productId,
    required String kind,
    required String filePath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException('You must be signed in to add a document');
    }
    final extension = filePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    // Own folder: the storage rules and the table's check both require it.
    final path =
        '$userId/documents/${DateTime.now().millisecondsSinceEpoch}.$extension';
    try {
      await _client.storage.from(_receiptsBucket).upload(path, File(filePath));
      // file_url holds the path too; the link is signed when products load.
      await _client.from('product_documents').insert({
        'product_id': productId,
        'kind': kind,
        'file_url': path,
        'file_path': path,
      });
    } catch (e) {
      await deleteReceiptImage(path); // don't leave an unattached file behind
      throw ServerException('Failed to add document: $e');
    }
  }

  @override
  Future<void> deleteDocument({
    required String id,
    required String path,
  }) async {
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
