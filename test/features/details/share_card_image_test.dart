import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
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

Future<Uint8List> greyPhoto() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 600, 400), Paint()..color = const Color(0xFF888888));
  final image = await recorder.endRecording().toImage(600, 400);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

ShareCardData data({Uint8List? photo, String? fontFamily}) => ShareCardData(
      brandName: 'Sakk',
      title: 'Samsung 55" Crystal UHD TV',
      subtitle: 'Samsung · Electronics',
      statusLabel: 'Active · 412 days left',
      statusColor: const Color(0xFF16A34A),
      rows: const [('Store', 'B.TECH'), ('Price', '18,500 EGP'), ('Warranty ends', 'Dec 1, 2027')],
      receiptLabel: 'Receipt',
      footer: 'Sakk — AI Warranty Manager',
      textDirection: TextDirection.ltr,
      photoBytes: photo,
      fontFamily: fontFamily,
    );

void main() {
  setUp(() => PathProviderPlatform.instance = _Paths(Directory.systemTemp.createTempSync('share_card').path));

  Future<ui.Image> decode(String path) async =>
      (await (await ui.instantiateImageCodec(File(path).readAsBytesSync())).getNextFrame()).image;

  testWidgets('with a receipt photo: header, details and the receipt', (tester) async {
    await tester.runAsync(() async {
      final withPhoto = await decode(await composeShareCard(data(photo: await greyPhoto())));
      final withoutPhoto = await decode(await composeShareCard(data()));
      expect(withPhoto.width, 1080);
      expect(withoutPhoto.width, 1080);
      // The receipt section (photo scaled to the card width) adds height.
      expect(withPhoto.height - withoutPhoto.height, greaterThan(500));
    });
  });

  // Renders previews with the real font when CAIRO_FONT and PREVIEW_DIR are
  // set (used to eyeball the design; skipped in normal runs).
  testWidgets('previews', (tester) async {
    final font = Platform.environment['CAIRO_FONT'];
    final out = Platform.environment['PREVIEW_DIR'];
    if (font == null || out == null) return;
    await tester.runAsync(() async {
      final loader = FontLoader('CairoPreview')..addFont(Future.value(ByteData.sublistView(File(font).readAsBytesSync())));
      await loader.load();
      final receipt = File('$out/receipt.png').readAsBytesSync();
      File(await composeShareCard(data(photo: receipt, fontFamily: 'CairoPreview'))).copySync('$out/card_en.png');
      File(await composeShareCard(ShareCardData(
        brandName: 'صك',
        title: 'غسالة توشيبا العربي فول أوتوماتيك ٧ كيلو',
        subtitle: 'توشيبا العربي · أجهزة منزلية',
        statusLabel: 'نشط · باقي ٦٧٣ يومًا',
        statusColor: const Color(0xFF16A34A),
        rows: const [('المتجر', 'بي تك'), ('السعر', '١٢٬٥٠٠ ج.م'), ('ينتهي الضمان', '١٥ أغسطس ٢٠٢٨'), ('الرقم التسلسلي', 'TA7K-99812')],
        receiptLabel: 'إيصال',
        footer: 'صك — مدير الضمانات الذكي',
        textDirection: TextDirection.rtl,
        fontFamily: 'CairoPreview',
      ))).copySync('$out/card_ar.png');
    });
  });
}
