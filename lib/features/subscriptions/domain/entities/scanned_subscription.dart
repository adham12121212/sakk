import 'package:equatable/equatable.dart';

import 'billing_cycle.dart';
import 'subscription_category.dart';

/// What the AI read from a screenshot or a pasted message. Every field may
/// be missing; the user reviews them in the form before saving.
class ScannedSubscription extends Equatable {
  final String? serviceName;
  final String? planName;
  final double? price;
  final String? currency;
  final BillingCycle? billingCycle;

  /// The next renewal, when the source shows it.
  final DateTime? nextRenewalDate;

  /// A payment that already happened (e.g. a bank SMS), when that's all the
  /// source shows.
  final DateTime? chargeDate;

  /// Card type and last 4 digits, or the wallet's name.
  final String? paymentMethod;
  final SubscriptionCategory category;
  final double confidence;

  const ScannedSubscription({
    this.serviceName,
    this.planName,
    this.price,
    this.currency,
    this.billingCycle,
    this.nextRenewalDate,
    this.chargeDate,
    this.paymentMethod,
    this.category = SubscriptionCategory.other,
    this.confidence = 0,
  });

  @override
  List<Object?> get props => [
    serviceName,
    planName,
    price,
    currency,
    billingCycle,
    nextRenewalDate,
    chargeDate,
    paymentMethod,
    category,
    confidence,
  ];
}
