import '../../products/domain/entities/product_entity.dart';

/// Money spent per year, newest first (years with no priced product are
/// left out).
List<MapEntry<int, double>> spendingByYear(List<ProductEntity> products) {
  final totals = <int, double>{};
  for (final p in products) {
    if (p.price == null) continue;
    totals[p.purchaseDate.year] = (totals[p.purchaseDate.year] ?? 0) + p.price!;
  }
  return totals.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
}

/// The stores where the most was spent, biggest first. Store names are
/// grouped ignoring case and extra spaces ("B.TECH" and "b.tech ").
List<MapEntry<String, double>> topStores(List<ProductEntity> products, {int limit = 5}) {
  final totals = <String, double>{};
  final displayName = <String, String>{};
  for (final p in products) {
    final store = p.store?.trim();
    if (p.price == null || store == null || store.isEmpty) continue;
    final key = store.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    displayName.putIfAbsent(key, () => store);
    totals[key] = (totals[key] ?? 0) + p.price!;
  }
  final ranked = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in ranked.take(limit)) MapEntry(displayName[e.key]!, e.value)];
}
