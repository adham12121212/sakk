import 'entities/user_subscription.dart';

/// Monthly cost per currency (yearly plans spread over 12 months). The app
/// has no exchange rates, so currencies are never added together.
Map<String, double> monthlyTotalsByCurrency(
  Iterable<UserSubscription> subscriptions,
) {
  final totals = <String, double>{};
  for (final s in subscriptions) {
    totals.update(
      s.currency,
      (sum) => sum + s.monthlyCost,
      ifAbsent: () => s.monthlyCost,
    );
  }
  return totals;
}

/// [subscriptions] ordered by the nearest renewal first.
List<UserSubscription> sortedByRenewal(
  Iterable<UserSubscription> subscriptions,
) {
  return subscriptions.toList()
    ..sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));
}
