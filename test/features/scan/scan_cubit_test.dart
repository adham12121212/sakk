import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/Failure.dart';
import 'package:sakk/core/service/warranty_notification_service.dart';
import 'package:sakk/features/category/domain/entities/product_category.dart';
import 'package:sakk/features/products/domain/enties/product_entity.dart';
import 'package:sakk/features/products/domain/enties/scanned_receipt.dart';
import 'package:sakk/features/products/domain/usecase/add_product_usecase.dart';
import 'package:sakk/features/products/domain/usecase/scan_receipt_usecase.dart';
import 'package:sakk/features/products/presentation/cubit/product_cubit.dart';
import 'package:sakk/features/scan/presentation/cubit/scan_cubit.dart';

class _Scan implements ScanReceiptUseCase {
  final discarded = <String>[];

  @override
  Future<Either<Failure, ScannedReceiptData>> call({required String imagePath}) async => const Right(
        ScannedReceiptData(productName: 'TV', receiptPath: 'u1/1.jpg', serialNumber: 'SN1', invoiceNumber: 'INV9'),
      );

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
      Right<Failure, ProductEntity>(ProductEntity(id: '1', name: 'TV', purchaseDate: DateTime(2026), warrantyMonths: 12)),
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

ScanCubit cubit(_Scan scan, _Add add) => ScanCubit(
      scanReceiptUseCase: scan,
      addProductUseCase: add,
      productsCubit: _Products(),
      warrantyNotificationService: _Notifications(),
    );

void main() {
  test('leaving without saving deletes the uploaded photo', () async {
    final scan = _Scan();
    final c = cubit(scan, _Add());
    await c.processReceipt('x.jpg');
    await c.close();
    expect(scan.discarded, ['u1/1.jpg']);
  });

  test('saving keeps the photo and saves the scanned extras', () async {
    final scan = _Scan();
    final add = _Add();
    final c = cubit(scan, add);
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
    final c = cubit(scan, _Add())..startManualEntry();
    expect(c.isManualEntry, isTrue);
    final scanned = (c.state as ScanLoaded).scanned;
    final today = DateTime.now();
    expect(scanned.productName, isNull);
    expect(scanned.purchaseDate!.day, today.day);
    await c.close();
    expect(scan.discarded, isEmpty);
  });
}
