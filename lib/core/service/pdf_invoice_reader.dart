import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// A PDF invoice turned into what the receipt scanner understands.
class PdfInvoice {
  const PdfInvoice({required this.imagePath, this.text});

  /// PNG of the first page. It's stored as the product's invoice photo, so
  /// the Invoice tab, share and download work exactly as for scanned photos.
  final String imagePath;

  /// The PDF's own text (online-store invoices have a text layer), or null
  /// for scanned PDFs that are just images. Exact, so the scanner prefers it
  /// for prices, dates and serial numbers.
  final String? text;
}

/// The PDF couldn't be opened (damaged, password-protected, no pages...).
class PdfInvoiceException implements Exception {
  const PdfInvoiceException();
}

class PdfInvoiceReader {
  /// Longest side of the rendered page; matches the 2000px photo limit.
  static const _maxPixels = 2000;

  /// The product details are almost always on the first pages.
  static const _textPages = 3;
  static const _maxTextLength = 6000;

  Future<PdfInvoice> read(Uint8List pdfBytes) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openData(
        pdfBytes,
        sourceName: 'invoice.pdf',
      );
      if (document.pages.isEmpty) throw const PdfInvoiceException();

      final imagePath = await _renderFirstPage(document.pages.first);

      final buffer = StringBuffer();
      for (final page in document.pages.take(_textPages)) {
        final text = (await page.loadText())?.fullText.trim();
        if (text != null && text.isNotEmpty) buffer.writeln(text);
      }
      final text = buffer.toString().trim();

      return PdfInvoice(
        imagePath: imagePath,
        text: text.isEmpty
            ? null
            : text.substring(0, text.length.clamp(0, _maxTextLength)),
      );
    } on PdfInvoiceException {
      rethrow;
    } catch (_) {
      // pdfrx throws for damaged and password-protected files alike.
      throw const PdfInvoiceException();
    } finally {
      await document?.dispose();
    }
  }

  Future<String> _renderFirstPage(PdfPage page) async {
    final scale =
        _maxPixels / (page.width > page.height ? page.width : page.height);
    final width = (page.width * scale).round();
    final height = (page.height * scale).round();
    final rendered = await page.render(
      width: width,
      height: height,
      fullWidth: width.toDouble(),
      fullHeight: height.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    if (rendered == null) throw const PdfInvoiceException();

    ui.Image? image;
    try {
      image = await rendered.createImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw const PdfInvoiceException();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png.buffer.asUint8List());
      return file.path;
    } finally {
      image?.dispose();
      rendered.dispose();
    }
  }
}
