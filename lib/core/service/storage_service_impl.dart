import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';

class StorageServiceImpl implements StorageService {
  final SupabaseClient _client;
  StorageServiceImpl(this._client);

  @override
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required File file,
    bool upsert = true,
  }) async {
    await _client.storage.from(bucket).upload(
      path,
      file,
      fileOptions: FileOptions(upsert: upsert),
    );
  }

  @override
  String getPublicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  @override
  Future<void> deleteFile({required String bucket, required String path}) async {
    await _client.storage.from(bucket).remove([path]);
  }
}