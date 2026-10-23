import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Deletes the temporary files the app leaves behind: picked and scanned
/// photos, PDF invoice pages, share images, opened documents, the CSV export
/// and the PDF report. Each is written once and handed to an upload or the
/// share sheet, and nothing reads it after that, so without this they pile
/// up until the system clears the folder.
///
/// Runs at launch, so no share or upload is still using a file. Only files
/// directly in the temporary folders are removed, plus the copies
/// file_picker keeps in its own folder; other folders (the logo image cache)
/// are left alone.
class TempFileCleaner {
  TempFileCleaner({
    Future<List<Directory>> Function()? folders,
    DateTime Function()? now,
  }) : _folders = folders ?? _defaultFolders,
       _now = now ?? DateTime.now;

  final Future<List<Directory>> Function() _folders;
  final DateTime Function() _now;

  /// Newer files are kept, in case one is from a share that just finished.
  static const minAge = Duration(hours: 1);

  /// Returns how many files were deleted. Never throws.
  Future<int> clean() async {
    var deleted = 0;
    try {
      final cutoff = _now().subtract(minAge);
      final seen = <String>{};
      for (final folder in await _folders()) {
        for (final dir in [folder, Directory('${folder.path}/file_picker')]) {
          if (!seen.add(dir.absolute.path) || !await dir.exists()) continue;
          await for (final entity in dir.list(followLinks: false)) {
            if (entity is! File) continue;
            try {
              if ((await entity.lastModified()).isBefore(cutoff)) {
                await entity.delete();
                deleted++;
              }
            } catch (_) {
              // In use or already gone: try again next launch.
            }
          }
        }
      }
    } catch (_) {
      // Cleaning up is never worth an error.
    }
    return deleted;
  }

  // getTemporaryDirectory is where the app writes its own files (Caches on
  // iOS, the cache folder on Android); the system temp folder is where
  // image_picker puts photos on iOS.
  static Future<List<Directory>> _defaultFolders() async => [
    await getTemporaryDirectory(),
    Directory.systemTemp,
  ];
}
