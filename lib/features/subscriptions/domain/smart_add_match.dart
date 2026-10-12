import 'entities/billing_cycle.dart';
import 'entities/catalog_service.dart';
import 'entities/scanned_subscription.dart';
import 'renewal_schedule.dart';

/// Lowercase letters and digits only (Arabic letters kept), so "NETFLIX.COM"
/// and "Netflix" compare equal.
String _key(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9؀-ۿ]'), '');

/// The catalog service a scanned [name] refers to: an exact match first,
/// then the longest catalog name contained in it (or containing it).
CatalogService? matchCatalogService(
  String? name,
  List<CatalogService> catalog,
) {
  if (name == null) return null;
  final key = _key(name);
  if (key.isEmpty) return null;

  for (final service in catalog) {
    if (_key(service.name) == key) return service;
  }
  // Partial matches only for names long enough not to match by accident.
  if (key.length < 3) return null;
  CatalogService? best;
  var bestLength = 0;
  for (final service in catalog) {
    final serviceKey = _key(service.name);
    // Short names ("WE", "e&") would match inside unrelated words.
    if (serviceKey.length < 4) continue;
    if ((key.contains(serviceKey) || serviceKey.contains(key)) &&
        serviceKey.length > bestLength) {
      best = service;
      bestLength = serviceKey.length;
    }
  }
  return best;
}

/// The plan of [service] that [scan] is on: same plan name, else same price,
/// currency and cycle. Null when nothing fits clearly.
CatalogPlan? matchPlan(CatalogService service, ScannedSubscription scan) {
  bool cycleFits(CatalogPlan p) =>
      scan.billingCycle == null || p.billingCycle == scan.billingCycle;

  final planName = scan.planName;
  if (planName != null) {
    final byName = service.plans
        .where((p) => _key(p.name) == _key(planName) && cycleFits(p))
        .toList();
    if (byName.length == 1) return byName.single;
  }
  final price = scan.price;
  if (price != null) {
    final byPrice = service.plans
        .where(
          (p) =>
              (p.price - price).abs() < 0.01 &&
              p.currency == (scan.currency ?? 'EGP') &&
              cycleFits(p),
        )
        .toList();
    if (byPrice.length == 1) return byPrice.single;
  }
  return null;
}

/// The renewal date to suggest for [scan] on [cycle]: its next renewal if
/// shown, else one cycle after the charge it shows, else one cycle from
/// today. Never in the past.
DateTime suggestedRenewal(
  ScannedSubscription scan,
  BillingCycle cycle,
  DateTime today,
) {
  final next = scan.nextRenewalDate;
  if (next != null) return nextRenewalOnOrAfter(next, cycle, today);
  final charge = scan.chargeDate;
  if (charge != null) {
    return nextRenewalOnOrAfter(
      addMonthsClamped(charge, cycle.months),
      cycle,
      today,
    );
  }
  return addMonthsClamped(
    DateTime(today.year, today.month, today.day),
    cycle.months,
  );
}
