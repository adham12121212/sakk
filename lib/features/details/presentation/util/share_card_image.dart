import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Builds one PNG: the receipt photo on top and the product details drawn
/// underneath. Apps like Messenger often drop the text that comes with a
/// shared photo; with the details inside the image nothing gets lost.
Future<String> composeShareCard({
  required Uint8List photoBytes,
  required String title,
  required List<String> lines,
  required String footer,
  required TextDirection textDirection,
}) async {
  const width = 1080.0;
  const padding = 56.0;
  const textWidth = width - padding * 2;
  // Very long receipts are scaled down to keep the image a sensible size.
  const maxPhotoHeight = 1600.0;

  final codec = await ui.instantiateImageCodec(photoBytes, targetWidth: width.toInt());
  final photo = (await codec.getNextFrame()).image;
  final scale = photo.height > maxPhotoHeight ? maxPhotoHeight / photo.height : 1.0;
  final photoSize = Size(photo.width * scale, photo.height * scale);

  TextPainter paint(String text, double size, FontWeight weight, Color color) => TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.35)),
        textDirection: textDirection,
        textAlign: TextAlign.start,
      )..layout(maxWidth: textWidth);

  final titlePainter = paint(title, 46, FontWeight.w700, const Color(0xFF0F172A));
  final linePainters = [for (final line in lines) paint(line, 32, FontWeight.w400, const Color(0xFF334155))];
  final footerPainter = paint(footer, 26, FontWeight.w600, const Color(0xFF4A5CFA));

  final textHeight = titlePainter.height +
      24 +
      linePainters.fold<double>(0, (sum, p) => sum + p.height + 10) +
      24 +
      footerPainter.height;
  final height = photoSize.height + padding * 2 + textHeight;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFFFFFFFF));
  paintImage(
    canvas: canvas,
    rect: Rect.fromLTWH((width - photoSize.width) / 2, 0, photoSize.width, photoSize.height),
    image: photo,
    filterQuality: FilterQuality.high,
  );
  // A thin brand-coloured line between the photo and the details.
  canvas.drawRect(Rect.fromLTWH(0, photoSize.height, width, 8), Paint()..color = const Color(0xFF4A5CFA));

  // Right-aligned for Arabic, left-aligned otherwise.
  double x(TextPainter p) => textDirection == TextDirection.rtl ? width - padding - p.width : padding;
  var y = photoSize.height + padding;
  titlePainter.paint(canvas, Offset(x(titlePainter), y));
  y += titlePainter.height + 24;
  for (final p in linePainters) {
    p.paint(canvas, Offset(x(p), y));
    y += p.height + 10;
  }
  y += 14;
  footerPainter.paint(canvas, Offset(x(footerPainter), y));

  final image = await recorder.endRecording().toImage(width.toInt(), height.ceil());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  photo.dispose();
  image.dispose();
  if (png == null) throw StateError('Could not encode the share image');

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sakk_share_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(png.buffer.asUint8List());
  return file.path;
}
