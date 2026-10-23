import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/pro/domain/pro_limit.dart';
import '../error/exceptions.dart';

/// A photo uploaded for the AI to read.
class UploadedReceipt {
  const UploadedReceipt({required this.path, required this.signedUrl});

  /// Storage path in the receipts bucket (`<user id>/<file>`).
  final String path;
  final String signedUrl;
}

/// The AI reading pipeline shared by receipt scanning and subscription smart
/// add: upload a photo to the user's receipts folder, call the
/// `extract-receipt` edge function, and turn its error statuses into codes
/// the UI can explain (see userFacingError).
class ReceiptAiClient {
  ReceiptAiClient(this._client);

  final SupabaseClient _client;

  static const bucket = 'receipts';
  static const _functionName = 'extract-receipt';

  /// The function found nothing usable in the photo or text (422).
  static const unreadable = 'unreadable_receipt';

  /// The AI provider's rate limit was hit; try again shortly (503).
  static const aiBusy = 'ai_busy';

  /// Uploads [imagePath] for the signed-in user. The signed URL lasts
  /// [expiry]; the edge function only accepts URLs to the user's own folder.
  Future<UploadedReceipt> upload(
    String imagePath, {
    required Duration expiry,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException('You must be signed in to scan a receipt');
    }

    // .png for rendered PDF pages, .jpg for photos; the upload's content
    // type follows the extension.
    final extension = imagePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage.from(bucket).upload(path, File(imagePath));
    try {
      final signedUrl = await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiry.inSeconds);
      return UploadedReceipt(path: path, signedUrl: signedUrl);
    } catch (_) {
      await delete(path);
      rethrow;
    }
  }

  /// Calls the edge function with [body] and returns its JSON answer.
  /// Throws [ServerException] with [unreadable] or [aiBusy] for those cases,
  /// and with a [ProLimit] code when today's scans are used up.
  ///
  /// Each call is one scan from the daily quota (given back by the function
  /// if it fails on its side), so the plan status re-reads its counter.
  Future<Map<String, dynamic>> extract(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: body,
      );
      return response.data as Map<String, dynamic>;
    } on FunctionException catch (e) {
      final limit = ProLimit.codeFor(e);
      if (limit != null) throw ServerException(limit);
      if (e.status == 422) throw ServerException(unreadable);
      if (e.status == 503) throw ServerException(aiBusy);
      rethrow;
    } finally {
      ProLimit.notifyUsageChanged();
    }
  }

  /// Deletes an uploaded photo. Best effort: a leftover photo is harmless,
  /// so this never fails the flow.
  Future<void> delete(String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (_) {}
  }
}
