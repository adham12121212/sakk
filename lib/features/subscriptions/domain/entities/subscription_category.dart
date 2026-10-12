enum SubscriptionCategory {
  streaming,
  music,
  gaming,
  cloud,
  productivity,
  ai,
  delivery,
  telecom,
  other,
}

extension SubscriptionCategoryX on SubscriptionCategory {
  static SubscriptionCategory fromName(String? raw) {
    return SubscriptionCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => SubscriptionCategory.other,
    );
  }
}
