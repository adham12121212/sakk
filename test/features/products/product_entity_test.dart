import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/products/domain/entities/extra_warranty.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';

/// A product whose warranty ends [days] days from today.
ProductEntity endingIn(int days, {List<ExtraWarranty> extras = const []}) {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day + days);
  return ProductEntity(
    id: 'p',
    name: 'TV',
    purchaseDate: DateTime(end.year - 1, end.month, end.day),
    warrantyMonths: 12,
    extraWarranties: extras,
  );
}

void main() {
  group('warranty dates', () {
    test('end date adds the warranty months to the purchase date', () {
      final p = ProductEntity(
        id: 'p',
        name: 'TV',
        purchaseDate: DateTime(2026, 3, 15),
        warrantyMonths: 24,
      );
      expect(p.warrantyEndDate, DateTime(2028, 3, 15));
    });

    test(
      'month overflow rolls over like DateTime (Jan 31 + 1 month = Mar 3)',
      () {
        final p = ProductEntity(
          id: 'p',
          name: 'TV',
          purchaseDate: DateTime(2026, 1, 31),
          warrantyMonths: 1,
        );
        expect(p.warrantyEndDate, DateTime(2026, 3, 3));
      },
    );

    test('status: active, expiring within 3 months, expired', () {
      expect(endingIn(200).status, WarrantyStatus.active);
      expect(endingIn(91).status, WarrantyStatus.active);
      expect(endingIn(90).status, WarrantyStatus.expiring);
      expect(endingIn(1).status, WarrantyStatus.expiring);
      expect(endingIn(0).status, WarrantyStatus.expired);
      expect(endingIn(-5).status, WarrantyStatus.expired);
    });
  });

  group('extra warranties', () {
    test('a later extra warranty extends coverage and status', () {
      final base = endingIn(-10); // manufacturer warranty already over
      final extended = ProductEntity(
        id: 'p',
        name: 'TV',
        purchaseDate: base.purchaseDate,
        warrantyMonths: 12,
        extraWarranties: [
          ExtraWarranty(
            id: 'w',
            provider: 'Store',
            startDate: base.manufacturerWarrantyEndDate,
            months: 24,
          ),
        ],
      );
      expect(extended.manufacturerWarrantyEndDate, base.warrantyEndDate);
      expect(extended.warrantyEndDate.isAfter(base.warrantyEndDate), isTrue);
      expect(extended.status, WarrantyStatus.active);
    });

    test('an extra warranty ending earlier does not shorten coverage', () {
      final p = endingIn(
        300,
        extras: [
          ExtraWarranty(
            id: 'w',
            provider: 'Store',
            startDate: DateTime(2020, 1, 1),
            months: 12,
          ),
        ],
      );
      expect(p.warrantyEndDate, p.manufacturerWarrantyEndDate);
    });
  });

  group('return window', () {
    test('no return window when returnDays is null', () {
      final p = ProductEntity(
        id: 'p',
        name: 'TV',
        purchaseDate: DateTime(2026, 1, 1),
        warrantyMonths: 12,
      );
      expect(p.returnByDate, isNull);
      expect(p.daysToReturn, isNull);
    });

    test('return-by date and days left', () {
      final today = DateTime.now();
      final bought = DateTime(today.year, today.month, today.day - 4);
      final p = ProductEntity(
        id: 'p',
        name: 'TV',
        purchaseDate: bought,
        warrantyMonths: 12,
        returnDays: 14,
      );
      expect(
        p.returnByDate,
        DateTime(bought.year, bought.month, bought.day + 14),
      );
      expect(p.daysToReturn, 10);
    });

    test('closed window gives negative days', () {
      final p = ProductEntity(
        id: 'p',
        name: 'TV',
        purchaseDate: DateTime(2020, 1, 1),
        warrantyMonths: 12,
        returnDays: 14,
      );
      expect(p.daysToReturn! < 0, isTrue);
    });
  });
}
