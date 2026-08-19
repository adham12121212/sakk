
enum ProductCategory {
  electronics,
  appliances,
  furniture,
  vehicles,
  accessories,
  other,
}

extension ProductCategoryX on ProductCategory {

  static ProductCategory fromName(String? raw) {
    return ProductCategory.values.firstWhere(
          (c) => c.name == raw,
      orElse: () => ProductCategory.other,
    );
  }
}