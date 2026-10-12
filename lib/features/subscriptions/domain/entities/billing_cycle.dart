enum BillingCycle { monthly, yearly }

extension BillingCycleX on BillingCycle {
  /// Unknown values read as monthly, the most common cycle.
  static BillingCycle fromName(String? raw) {
    return BillingCycle.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => BillingCycle.monthly,
    );
  }

  int get months => this == BillingCycle.yearly ? 12 : 1;
}
