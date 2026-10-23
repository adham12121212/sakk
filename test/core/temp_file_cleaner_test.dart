import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/service/temp_file_cleaner.dart';

void main() {
  late Directory temp;
  final now = DateTime(2026, 10, 23, 12);

  setUp(() => temp = Directory.systemTemp.createTempSync('cleaner_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  File fileAt(String name, Duration age) {
    final file = File('${temp.path}/$name')..createSync(recursive: true);
    file.setLastModifiedSync(now.subtract(age));
    return file;
  }

  test(
    'deletes old leftover files, keeps recent ones and other folders',
    () async {
      final oldShare = fileAt('sakk_share_1.png', const Duration(days: 2));
      final oldPick = fileAt(
        'file_picker/invoice.pdf',
        const Duration(hours: 3),
      );
      final recent = fileAt('sakk_report.pdf', const Duration(minutes: 10));
      final logoCache = fileAt(
        'libCachedImageData/logo.png',
        const Duration(days: 9),
      );

      final deleted = await TempFileCleaner(
        folders: () async => [temp, temp],
        now: () => now,
      ).clean();

      expect(deleted, 2);
      expect(oldShare.existsSync(), isFalse);
      expect(oldPick.existsSync(), isFalse);
      expect(recent.existsSync(), isTrue);
      expect(logoCache.existsSync(), isTrue);
    },
  );

  test('a missing folder is not an error', () async {
    final cleaner = TempFileCleaner(
      folders: () async => [Directory('${temp.path}/nope')],
      now: () => now,
    );
    expect(await cleaner.clean(), 0);
  });
}
