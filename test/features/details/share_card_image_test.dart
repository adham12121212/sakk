import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sakk/features/details/presentation/util/share_card_image.dart';

class _Paths extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  _Paths(this.dir);
  final String dir;
  @override
  Future<String?> getTemporaryPath() async => dir;
}

void main() {
  testWidgets('one image: the photo on top, the details under it', (tester) async {
    final tmp = Directory.systemTemp.createTempSync('share_card');
    PathProviderPlatform.instance = _Paths(tmp.path);

    await tester.runAsync(() async {
      // A 600x400 grey "receipt photo".
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 600, 400), Paint()..color = const Color(0xFF888888));
      final photo = await recorder.endRecording().toImage(600, 400);
      final photoPng = (await photo.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

      final path = await composeShareCard(
        photoBytes: photoPng,
        title: 'Samsung 55" TV',
        lines: ['Brand: Samsung', 'Store: B.TECH', 'Expires: 2027-12-01'],
        footer: 'Sakk',
        textDirection: TextDirection.ltr,
      );

      final card = await (await ui.instantiateImageCodec(File(path).readAsBytesSync())).getNextFrame();
      expect(card.image.width, 1080);
      // The photo is scaled to 1080 wide (720 tall) and the details add more.
      expect(card.image.height, greaterThan(720 + 200));
      if (Platform.environment['SHARE_CARD_OUT'] case final out?) File(path).copySync(out);
    });
  });
}
