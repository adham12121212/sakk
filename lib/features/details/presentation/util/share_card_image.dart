import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constant/app_colors.dart';

/// Everything shown on the shared product card.
class ShareCardData {
  const ShareCardData({
    required this.brandName,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    required this.rows,
    required this.receiptLabel,
    required this.footer,
    required this.textDirection,
    this.photoBytes,
    this.fontFamily,
  });

  /// App name in the header ("Sakk" / "صك").
  final String brandName;
  final String title;

  /// e.g. "Samsung · Electronics"; empty to leave out.
  final String subtitle;

  /// e.g. "Active · 412 days left", in [statusColor].
  final String statusLabel;
  final Color statusColor;

  /// Label/value pairs for the details table.
  final List<(String, String)> rows;
  final String receiptLabel;
  final String footer;
  final TextDirection textDirection;

  /// The receipt photo; the receipt section is left out when null.
  final Uint8List? photoBytes;

  /// The app's font (Cairo), so the card matches the app.
  final String? fontFamily;
}

// Palette matching the app's "soft & airy" theme.
const _page = Color(0xFFF1F5F9);
const _card = Color(0xFFFFFFFF);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _divider = Color(0xFFE2E8F0);
const _gradient = AppColors.brandGradientColors;

/// Builds one PNG summarizing a product: a branded header with the warranty
/// status, the product's details as a table and the receipt photo. Apps like
/// Messenger often drop the text that comes with a shared photo; with the
/// details inside the image nothing gets lost.
Future<String> composeShareCard(ShareCardData data) async {
  const width = 1080.0;
  const margin = 40.0; // page edge to card
  const pad = 44.0; // card edge to content
  const inner = width - margin * 2 - pad * 2;
  const headerHeight = 168.0;
  const maxPhotoHeight = 1300.0;
  final rtl = data.textDirection == TextDirection.rtl;

  TextPainter text(String value, double size, FontWeight weight, Color color, {double? maxWidth, int? maxLines}) =>
      TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontFamily: data.fontFamily, fontSize: size, fontWeight: weight, color: color, height: 1.3),
        ),
        textDirection: data.textDirection,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: maxWidth ?? inner);

  // ---- measure
  final brand = text(data.brandName, 44, FontWeight.w800, const Color(0xFFFFFFFF));
  final status = text(data.statusLabel, 28, FontWeight.w700, data.statusColor, maxWidth: inner * 0.6);
  final title = text(data.title, 50, FontWeight.w800, _ink, maxLines: 3);
  final subtitle = data.subtitle.isEmpty ? null : text(data.subtitle, 30, FontWeight.w500, _muted);
  const labelWidth = inner * 0.42;
  final rows = [
    for (final (label, value) in data.rows)
      (
        text(label, 28, FontWeight.w500, _muted, maxWidth: labelWidth),
        text(value, 30, FontWeight.w700, _ink, maxWidth: inner - labelWidth - 24),
      ),
  ];
  const rowGap = 22.0;
  final rowsHeight = rows.fold<double>(0, (h, r) => h + (r.$1.height > r.$2.height ? r.$1.height : r.$2.height) + rowGap * 2);
  final detailsHeight = pad + title.height + (subtitle == null ? 0 : 8 + subtitle.height) + 28 + rowsHeight + pad - rowGap;

  ui.Image? photo;
  Size photoSize = Size.zero;
  final receiptTitle = text(data.receiptLabel, 30, FontWeight.w700, _ink);
  if (data.photoBytes != null) {
    final codec = await ui.instantiateImageCodec(data.photoBytes!, targetWidth: inner.toInt());
    photo = (await codec.getNextFrame()).image;
    final scale = photo.height > maxPhotoHeight ? maxPhotoHeight / photo.height : 1.0;
    photoSize = Size(photo.width * scale, photo.height * scale);
  }
  final receiptHeight = photo == null ? 0.0 : pad + receiptTitle.height + 20 + photoSize.height + pad;
  final footer = text(data.footer, 26, FontWeight.w600, _muted);

  final height = headerHeight +
      margin +
      detailsHeight +
      (photo == null ? 0 : margin * 0.75 + receiptHeight) +
      margin +
      footer.height +
      margin;

  // ---- paint
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = _page);

  // Header: brand gradient, app name on one side, status pill on the other.
  final headerRect = Rect.fromLTWH(0, 0, width, headerHeight);
  canvas.drawRect(
    headerRect,
    Paint()..shader = ui.Gradient.linear(headerRect.topLeft, headerRect.bottomRight, _gradient),
  );
  final headerCenter = headerHeight / 2;
  brand.paint(canvas, Offset(rtl ? width - margin - brand.width : margin, headerCenter - brand.height / 2));
  const pillPadH = 26.0, pillPadV = 12.0;
  final pillSize = Size(status.width + pillPadH * 2, status.height + pillPadV * 2);
  final pillLeft = rtl ? margin : width - margin - pillSize.width;
  final pill = RRect.fromRectAndRadius(
    Rect.fromLTWH(pillLeft, headerCenter - pillSize.height / 2, pillSize.width, pillSize.height),
    Radius.circular(pillSize.height / 2),
  );
  canvas.drawRRect(pill, Paint()..color = const Color(0xFFFFFFFF));
  status.paint(canvas, Offset(pillLeft + pillPadH, pill.top + pillPadV));

  void card(double top, double cardHeight) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, top, width - margin * 2, cardHeight),
      const Radius.circular(28),
    );
    canvas.drawRRect(rect.shift(const Offset(0, 6)), Paint()
      ..color = const Color(0x140F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    canvas.drawRRect(rect, Paint()..color = _card);
  }

  double start(TextPainter p) => rtl ? width - margin - pad - p.width : margin + pad;
  double end(TextPainter p) => rtl ? margin + pad : width - margin - pad - p.width;

  // Details card: title, subtitle, then label/value rows with dividers.
  var y = headerHeight + margin;
  card(y, detailsHeight);
  y += pad;
  title.paint(canvas, Offset(start(title), y));
  y += title.height;
  if (subtitle != null) {
    y += 8;
    subtitle.paint(canvas, Offset(start(subtitle), y));
    y += subtitle.height;
  }
  y += 28;
  for (final (label, value) in rows) {
    // A divider above every row, the first one separating it from the title.
    canvas.drawRect(Rect.fromLTWH(margin + pad, y, inner, 2), Paint()..color = _divider);
    y += rowGap;
    final rowHeight = label.height > value.height ? label.height : value.height;
    label.paint(canvas, Offset(start(label), y + (rowHeight - label.height) / 2));
    value.paint(canvas, Offset(end(value), y + (rowHeight - value.height) / 2));
    y += rowHeight + rowGap;
  }
  y = headerHeight + margin + detailsHeight;

  // Receipt card.
  if (photo != null) {
    y += margin * 0.75;
    card(y, receiptHeight);
    receiptTitle.paint(canvas, Offset(start(receiptTitle), y + pad));
    final photoTop = y + pad + receiptTitle.height + 20;
    final photoRect = Rect.fromLTWH((width - photoSize.width) / 2, photoTop, photoSize.width, photoSize.height);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(photoRect, const Radius.circular(18)));
    paintImage(canvas: canvas, rect: photoRect, image: photo, filterQuality: FilterQuality.high);
    canvas.restore();
    y += receiptHeight;
  }

  // Footer, centered.
  y += margin;
  footer.paint(canvas, Offset((width - footer.width) / 2, y));

  final image = await recorder.endRecording().toImage(width.toInt(), height.ceil());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  photo?.dispose();
  image.dispose();
  if (png == null) throw StateError('Could not encode the share image');

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/sakk_share_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(png.buffer.asUint8List());
  return file.path;
}
