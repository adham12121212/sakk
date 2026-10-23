import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/service/pdf_invoice_reader.dart';
import 'package:sakk/core/service/warranty_notification_service.dart';
import 'package:sakk/features/products/data/product_data_source/product_data_source.dart';
import 'package:sakk/features/category/domain/entities/product_category.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';
import 'package:sakk/features/products/domain/entities/scanned_receipt.dart';
import 'package:sakk/features/products/domain/usecase/add_product_usecase.dart';
import 'package:sakk/features/products/domain/usecase/scan_receipt_usecase.dart';
import 'package:sakk/features/products/presentation/cubit/product_cubit.dart';
import 'package:sakk/features/scan/presentation/cubit/scan_cubit.dart';

class _Scan implements ScanReceiptUseCase {
  final discarded = <String>[];
  String? lastImagePath;
  String? lastPdfText;

  @override
  Future<Either<Failure, ScannedReceiptData>> call({
    required String imagePath,
    String? pdfText,
  }) async {
    lastImagePath = imagePath;
    lastPdfText = pdfText;
    return const Right(
      ScannedReceiptData(
        productName: 'TV',
        receiptPath: 'u1/1.jpg',
        serialNumber: 'SN1',
        invoiceNumber: 'INV9',
      ),
    );
  }

  String? lastAudioPath;

  /// What [voice] returns.
  Either<Failure, ScannedReceiptData> voiceResult = const Right(
    ScannedReceiptData(
      productName: 'Samsung TV',
      price: 20000,
      warrantyMonths: 24,
      transcript: 'اشتريت تليفزيون سامسونج بعشرين ألف وضمانه سنتين',
    ),
  );

  @override
  Future<Either<Failure, ScannedReceiptData>> voice({
    required String audioPath,
  }) async {
    lastAudioPath = audioPath;
    return voiceResult;
  }

  @override
  Future<void> discard(String receiptPath) async => discarded.add(receiptPath);
}

/// Records what was saved.
class _Add implements AddProductUseCase {
  Map<Symbol, dynamic>? saved;

  @override
  dynamic noSuchMethod(Invocation i) {
    saved = i.namedArguments;
    return Future.value(
      Right<Failure, ProductEntity>(
        ProductEntity(
          id: '1',
          name: 'TV',
          purchaseDate: DateTime(2026),
          warrantyMonths: 12,
        ),
      ),
    );
  }
}

class _Products implements ProductsCubit {
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Notifications implements WarrantyNotificationService {
  @override
  Future<void> scheduleFutureNotifications(ProductEntity product) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Returns [result] or throws [PdfInvoiceException] when it's null.
class _PdfReader implements PdfInvoiceReader {
  _PdfReader(this.result);
  final PdfInvoice? result;

  @override
  Future<PdfInvoice> read(Uint8List pdfBytes) async =>
      result ?? (throw const PdfInvoiceException());
}

ScanCubit _cubit(_Scan scan, _Add add, {PdfInvoiceReader? pdf}) => ScanCubit(
  scanReceiptUseCase: scan,
  addProductUseCase: add,
  productsCubit: _Products(),
  warrantyNotificationService: _Notifications(),
  pdfInvoiceReader: pdf,
);

void main() {
  test('leaving without saving deletes the uploaded photo', () async {
    final scan = _Scan();
    final c = _cubit(scan, _Add());
    await c.processReceipt('x.jpg');
    await c.close();
    expect(scan.discarded, ['u1/1.jpg']);
  });

  test('saving keeps the photo and saves the scanned extras', () async {
    final scan = _Scan();
    final add = _Add();
    final c = _cubit(scan, add);
    await c.processReceipt('x.jpg');
    await c.save(
      name: 'TV',
      warrantyMonths: 12,
      category: ProductCategory.electronics,
      currency: 'EGP',
      returnDays: 14,
      serialNumber: 'SN1',
      invoiceNumber: 'INV9',
    );
    await c.close();
    expect(scan.discarded, isEmpty);
    expect(add.saved![#returnDays], 14);
    expect(add.saved![#serialNumber], 'SN1');
    expect(add.saved![#invoiceNumber], 'INV9');
  });

  test('manual entry starts empty, dated today, with no photo', () async {
    final scan = _Scan();
    final c = _cubit(scan, _Add())..startManualEntry();
    expect(c.isManualEntry, isTrue);
    final scanned = (c.state as ScanLoaded).scanned;
    final today = DateTime.now();
    expect(scanned.productName, isNull);
    expect(scanned.purchaseDate!.day, today.day);
    await c.close();
    expect(scan.discarded, isEmpty);
  });

  test(
    'a PDF invoice is scanned as its first-page image plus its text',
    () async {
      final scan = _Scan();
      final c = _cubit(
        scan,
        _Add(),
        pdf: _PdfReader(
          const PdfInvoice(imagePath: '/tmp/page.png', text: 'Invoice No: 1'),
        ),
      );
      await c.processPdf(Uint8List(0));
      expect(scan.lastImagePath, '/tmp/page.png');
      expect(scan.lastPdfText, 'Invoice No: 1');
      expect(c.state, isA<ScanEditing>());
    },
  );

  test('a PDF that cannot be opened shows the PDF error', () async {
    final c = _cubit(_Scan(), _Add(), pdf: _PdfReader(null));
    await c.processPdf(Uint8List(0));
    expect(
      (c.state as ScanProcessingFailed).message,
      ProductDataSourceImpl.pdfUnreadable,
    );
  });

  group('add by voice', () {
    test('what was said fills the form, with nothing to delete', () async {
      final scan = _Scan();
      final c = _cubit(scan, _Add());
      await c.processVoice('/tmp/voice.m4a');
      expect(scan.lastAudioPath, '/tmp/voice.m4a');
      final scanned = (c.state as ScanEditing).scanned;
      expect(scanned.productName, 'Samsung TV');
      expect(scanned.warrantyMonths, 24);
      expect(scanned.transcript, contains('سامسونج'));
      await c.close();
      expect(scan.discarded, isEmpty);
    });

    test('nothing heard shows the voice message', () async {
      final scan = _Scan()
        ..voiceResult = const Left(
          ServerFailure(ProductDataSourceImpl.voiceUnheard),
        );
      final c = _cubit(scan, _Add());
      await c.processVoice('/tmp/voice.m4a');
      expect(
        (c.state as ScanProcessingFailed).message,
        ProductDataSourceImpl.voiceUnheard,
      );
    });
  });
}
