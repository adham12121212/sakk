import 'package:equatable/equatable.dart';

import 'billing_cycle.dart';
import 'subscription_category.dart';

/// A service the user pays for, picked from the catalog or entered by hand.
class UserSubscription extends Equatable {
  final String id;

  /// Null for a custom subscription.
  final String? catalogId;

  /// Set for a custom subscription.
  final String? customName;

  /// Name, domain and logo of the catalog service, when there is one.
  final String? catalogName;
  final String? domain;
  final String? logoUrl;

  final String? planName;
  final SubscriptionCategory category;
  final double price;
  final String currency;
  final BillingCycle billingCycle;

  /// Date only (no time of day).
  final DateTime nextRenewalDate;

  /// The day of the month it renews on (1–31). [nextRenewalDate] is on it,
  /// or on its month's last day when the month is shorter. Null where it
  /// isn't known (a cache from before it was stored); see [billingDay].
  final int? renewalDay;
  final String? paymentMethod;
  final String? notes;
  final DateTime? createdAt;

  const UserSubscription({
    required this.id,
    this.catalogId,
    this.customName,
    this.catalogName,
    this.domain,
    this.logoUrl,
    this.planName,
    this.category = SubscriptionCategory.other,
    required this.price,
    this.currency = 'EGP',
    required this.billingCycle,
    required this.nextRenewalDate,
    this.renewalDay,
    this.paymentMethod,
    this.notes,
    this.createdAt,
  });

  bool get isCustom => catalogId == null;

  /// The day of the month it renews on: [renewalDay], or the date's own.
  int get billingDay => renewalDay ?? nextRenewalDate.day;

  /// What to show as the title. Empty only if the catalog service was deleted
  /// from a subscription that never had a custom name.
  String get name => customName ?? catalogName ?? planName ?? '';

  /// What it costs per month: a yearly price is spread over 12 months.
  double get monthlyCost => price / billingCycle.months;

  /// Days from [today] until the renewal; 0 on the day itself, negative once
  /// it has passed.
  int daysLeft(DateTime today) {
    final from = DateTime.utc(today.year, today.month, today.day);
    final to = DateTime.utc(
      nextRenewalDate.year,
      nextRenewalDate.month,
      nextRenewalDate.day,
    );
    return to.difference(from).inDays;
  }

  UserSubscription copyWith({DateTime? nextRenewalDate, int? renewalDay}) {
    return UserSubscription(
      id: id,
      catalogId: catalogId,
      customName: customName,
      catalogName: catalogName,
      domain: domain,
      logoUrl: logoUrl,
      planName: planName,
      category: category,
      price: price,
      currency: currency,
      billingCycle: billingCycle,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      renewalDay: renewalDay ?? this.renewalDay,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    catalogId,
    customName,
    catalogName,
    domain,
    logoUrl,
    planName,
    category,
    price,
    currency,
    billingCycle,
    nextRenewalDate,
    renewalDay,
    paymentMethod,
    notes,
    createdAt,
  ];
}
