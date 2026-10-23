import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/service/pdf_invoice_reader.dart';
import '../../../../core/service/review_prompter.dart';
import '../../../products/data/product_data_source/product_data_source.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../category/domain/entities/product_category.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/domain/entities/scanned_receipt.dart';
import '../../../products/domain/usecase/add_product_usecase.dart';
import '../../../products/domain/usecase/scan_receipt_usecase.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
part 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    ScanReceiptUseCase? scanReceiptUseCase,
    AddProductUseCase? addProductUseCase,
    ProductsCubit? productsCubit,
    WarrantyNotificationService? warrantyNotificationService,
    PdfInvoiceReader? pdfInvoiceReader,
    ReviewPrompter? reviewPrompter,
  }) : _reviewPrompter = reviewPrompter,
       _pdfInvoiceReader = pdfInvoiceReader ?? PdfInvoiceReader(),
       _scanReceiptUseCase = scanReceiptUseCase ?? getIt<ScanReceiptUseCase>(),
       _addProductUseCase = addProductUseCase ?? getIt<AddProductUseCase>(),
       _productsCubit = productsCubit ?? getIt<ProductsCubit>(),
       _warrantyNotificationService =
           warrantyNotificationService ?? getIt<WarrantyNotificationService>(),
       super(const ScanProcessing());

  final ScanReceiptUseCase _scanReceiptUseCase;
  final AddProductUseCase _addProductUseCase;
  final ProductsCubit _productsCubit;
  final WarrantyNotificationService _warrantyNotificationService;
  final PdfInvoiceReader _pdfInvoiceReader;

  /// Resolved lazily (getIt) so tests that don't register it aren't affected.
  final ReviewPrompter? _reviewPrompter;

  /// True when the user chose to type the details in instead of scanning, so
  /// there's no receipt image or confidence score to show.
  bool get isManualEntry => _isManualEntry;
  bool _isManualEntry = false;

  bool _saved = false;

  /// Leaving the flow without saving (back button, system back, failed scan)
  /// closes the cubit; the uploaded photo would then belong to nothing, so
  /// it's deleted rather than left in storage.
  @override
  Future<void> close() {
    final path = switch (state) {
      ScanLoaded(:final scanned) => scanned.receiptPath,
      _ => null,
    };
    if (!_saved && path != null) unawaited(_scanReceiptUseCase.discard(path));
    return super.close();
  }

  /// Opens the review form empty (purchase date defaults to today) for a
  /// product added without a receipt.
  void startManualEntry() {
    _isManualEntry = true;
    emit(
      ScanEditing(
        scanned: ScannedReceiptData(
          purchaseDate: DateTime.now(),
          confidence: 1,
        ),
      ),
    );
  }

  Future<void> processReceipt(String imagePath, {String? pdfText}) async {
    final result = await _scanReceiptUseCase(
      imagePath: imagePath,
      pdfText: pdfText,
    );
    if (isClosed) {
      // The user left while the scan was running: emitting now would throw,
      // and close() couldn't delete a photo it didn't know about yet.
      result.fold((_) {}, (scanned) {
        final path = scanned.receiptPath;
        if (path != null) unawaited(_scanReceiptUseCase.discard(path));
      });
      return;
    }

    result.fold(
      (failure) => emit(ScanProcessingFailed(failure.message)),
      (scanned) => emit(ScanEditing(scanned: scanned)),
    );
  }

  /// A product the user described out loud (Sakk Pro). Like a scan, but
  /// with no receipt photo, so nothing is left to delete if they leave.
  Future<void> processVoice(String audioPath) async {
    final result = await _scanReceiptUseCase.voice(audioPath: audioPath);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ScanProcessingFailed(failure.message)),
      (scanned) => emit(ScanEditing(scanned: scanned)),
    );
  }

  /// A PDF invoice (e.g. emailed by an online store): its first page becomes
  /// the invoice photo and its text goes to the scanner with it.
  Future<void> processPdf(Uint8List pdfBytes) async {
    final PdfInvoice invoice;
    try {
      invoice = await _pdfInvoiceReader.read(pdfBytes);
    } on PdfInvoiceException {
      if (!isClosed) {
        emit(const ScanProcessingFailed(ProductDataSourceImpl.pdfUnreadable));
      }
      return;
    }
    if (isClosed) return;
    await processReceipt(invoice.imagePath, pdfText: invoice.text);
  }

  void updatePurchaseDate(DateTime date) {
    final current = state;
    if (current is! ScanLoaded) return;
    emit(ScanEditing(scanned: current.scanned.copyWith(purchaseDate: date)));
  }

  Future<void> save({
    required String name,
    String? brand,
    double? price,
    required int warrantyMonths,
    String? store,
    String? notes,
    required ProductCategory category,
    required String currency,
    int? returnDays,
    String? serialNumber,
    String? invoiceNumber,
  }) async {
    final current = state;
    if (current is! ScanLoaded) return;

    final scanned = current.scanned;
    emit(ScanSaving(scanned: scanned));

    final result = await _addProductUseCase(
      name: name,
      brand: brand,
      price: price,
      purchaseDate: scanned.purchaseDate ?? DateTime.now(),
      warrantyMonths: warrantyMonths,
      imageUrl: scanned.receiptImageUrl,
      receiptUrl: scanned.receiptImageUrl,
      store: store,
      notes: notes,
      status: WarrantyStatus.active,
      currency: currency,
      category: category,
      returnDays: returnDays,
      serialNumber: serialNumber,
      invoiceNumber: invoiceNumber,
    );

    result.fold(
      (failure) =>
          emit(ScanSaveFailure(scanned: scanned, message: failure.message)),
      (product) {
        _saved = true;
        _productsCubit.refresh();
        final prompter =
            _reviewPrompter ??
            (getIt.isRegistered<ReviewPrompter>()
                ? getIt<ReviewPrompter>()
                : null);
        unawaited(prompter?.productSaved());
        _warrantyNotificationService.scheduleFutureNotifications(product);
        emit(ScanSaveSuccess(scanned: scanned));
      },
    );
  }
}
