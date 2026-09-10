import 'dart:io';

abstract class StorageService {
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required File file,
    bool upsert = true,
  });

  String getPublicUrl({required String bucket, required String path});

  Future<void> deleteFile({required String bucket, required String path});
}


