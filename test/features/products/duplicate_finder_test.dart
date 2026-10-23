import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/products/domain/duplicate_finder.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';

final saved = [
  ProductEntity(
    id: 'tv',
    name: 'LG 65" OLED evo TV',
    price: 64999,
    purchaseDate: DateTime(2026, 7, 3),
    warrantyMonths: 24,
    serialNumber: '507KRAB2201',
    invoiceNumber: 'RS-2026-00731',
  ),
  ProductEntity(
    id: 'kettle',
    name: 'Kettle',
    price: 900,
    purchaseDate: DateTime(2026, 9, 1),
    warrantyMonths: 6,
  ),
];

void main() {
  test('same invoice number, written differently, is a duplicate', () {
    final match = findDuplicate(
      saved,
      name: 'Something else',
      purchaseDate: DateTime(2020),
      invoiceNumber: 'rs 2026 00731',
    );
    expect(match?.product.id, 'tv');
    expect(match?.reason, DuplicateReason.sameInvoiceNumber);
  });

  test('Arabic-Indic digits match standard ones', () {
    final match = findDuplicate(
      saved,
      name: 'x',
      purchaseDate: DateTime(2020),
      serialNumber: '٥٠٧KRAB٢٢٠١',
    );
    expect(match?.reason, DuplicateReason.sameSerialNumber);
  });

  test(
    'same name on the same day is a duplicate, ignoring case and spaces',
    () {
      final match = findDuplicate(
        saved,
        name: '  kettle ',
        purchaseDate: DateTime(2026, 9, 1, 15, 30),
        price: 900,
      );
      expect(match?.product.id, 'kettle');
      expect(match?.reason, DuplicateReason.sameNameAndDate);
    },
  );

  test('same name and day but a different price is a different purchase', () {
    expect(
      findDuplicate(
        saved,
        name: 'Kettle',
        purchaseDate: DateTime(2026, 9, 1),
        price: 1200,
      ),
      isNull,
    );
  });

  test('same name on another day is not a duplicate', () {
    expect(
      findDuplicate(saved, name: 'Kettle', purchaseDate: DateTime(2026, 9, 2)),
      isNull,
    );
  });

  test('empty codes never match', () {
    expect(
      findDuplicate(
        saved,
        name: 'New',
        purchaseDate: DateTime(2026),
        serialNumber: ' ',
        invoiceNumber: '-',
      ),
      isNull,
    );
  });
}
