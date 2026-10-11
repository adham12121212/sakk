import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/analytics/domain/spending_insights.dart';
import 'package:sakk/features/products/domain/entities/product_entity.dart';

ProductEntity p(String id, double? price, int year, {String? store}) =>
    ProductEntity(id: id, name: id, price: price, store: store, purchaseDate: DateTime(year, 5, 1), warrantyMonths: 12);

void main() {
  final products = [
    p('tv', 18500, 2026, store: 'B.TECH'),
    p('fridge', 32000, 2025, store: 'Raya'),
    p('kettle', 900, 2026, store: 'b.tech '),
    p('gift', null, 2024, store: 'Carrefour'), // no price: ignored
  ];

  test('spending per year, newest first, skipping unpriced products', () {
    expect(spendingByYear(products).map((e) => (e.key, e.value)), [(2026, 19400.0), (2025, 32000.0)]);
  });

  test('top stores group names ignoring case and spaces', () {
    expect(topStores(products).map((e) => (e.key, e.value)), [('Raya', 32000.0), ('B.TECH', 19400.0)]);
    expect(topStores(products, limit: 1), hasLength(1));
  });
}
