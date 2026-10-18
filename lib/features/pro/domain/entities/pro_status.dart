import 'package:equatable/equatable.dart';

import '../pro_limit.dart';

/// Which plan the user is on, for the plan badge.
enum PlanKind { free, monthly, yearly, trial, billingIssue }

/// Today's use of one daily quota. [limit] and [remaining] are null when
/// there's no limit.
class Quota extends Equatable {
  const Quota({required this.used, this.limit, this.remaining});

  final int used;
  final int? limit;
  final int? remaining;

  bool get isUnlimited => limit == null;
  bool get isUsedUp => remaining != null && remaining! <= 0;

  factory Quota.fromJson(Map<String, dynamic>? json) => Quota(
        used: (json?['used'] as num?)?.toInt() ?? 0,
        limit: (json?['limit'] as num?)?.toInt(),
        remaining: (json?['remaining'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [used, limit, remaining];
}

/// How many of one item the user has, against the plan's [limit] (null:
/// no limit).
class ItemUsage extends Equatable {
  const ItemUsage({required this.count, this.limit});

  final int count;
  final int? limit;

  /// Adding one more would be refused.
  bool get isFull => limit != null && count >= limit!;

  factory ItemUsage.fromJson(Map<String, dynamic>? json) => ItemUsage(
        count: (json?['count'] as num?)?.toInt() ?? 0,
        limit: (json?['limit'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [count, limit];
}

/// The paid subscription as the store reports it (RevenueCat's CustomerInfo,
/// or the pro_subscriptions row the webhook keeps).
class ProEntitlement extends Equatable {
  const ProEntitlement({
    required this.isActive,
    this.productId,
    this.isTrial = false,
    this.expiresAt,
    this.willRenew = true,
    this.billingIssue = false,
  });

  final bool isActive;

  /// e.g. `sakk_pro:monthly` (Google Play product id and base plan).
  final String? productId;
  final bool isTrial;

  /// When the current period (or trial) ends; the renewal date if [willRenew].
  final DateTime? expiresAt;
  final bool willRenew;
  final bool billingIssue;

  /// Yearly when the product or base plan id says so (`...:yearly`,
  /// `..._annual`); monthly otherwise.
  bool get isYearly {
    final id = productId?.toLowerCase() ?? '';
    return id.contains('year') || id.contains('annual');
  }

  factory ProEntitlement.fromJson(Map<String, dynamic> json, {required bool isActive}) => ProEntitlement(
        isActive: isActive,
        productId: json['product_id'] as String?,
        isTrial: json['is_trial'] as bool? ?? false,
        expiresAt: DateTime.tryParse(json['active_until'] as String? ?? '')?.toLocal(),
        willRenew: json['will_renew'] as bool? ?? true,
        billingIssue: json['billing_issue'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [isActive, productId, isTrial, expiresAt, willRenew, billingIssue];
}

/// The user's plan and how much of it they've used, from the
/// get_usage_status database function.
class ProStatus extends Equatable {
  const ProStatus({
    this.isPro = false,
    this.entitlement,
    this.scan = const Quota(used: 0),
    this.chat = const Quota(used: 0),
    this.items = const {},
  });

  /// Before the first load, or signed out: the free plan with nothing used
  /// and no known limits, so nothing is blocked on the client (the server
  /// still enforces).
  static const unknown = ProStatus();

  final bool isPro;
  final ProEntitlement? entitlement;
  final Quota scan;
  final Quota chat;
  final Map<LimitedItem, ItemUsage> items;

  Quota quota(QuotaType type) => type == QuotaType.scan ? scan : chat;
  ItemUsage item(LimitedItem item) => items[item] ?? const ItemUsage(count: 0);

  PlanKind get plan {
    if (!isPro) return PlanKind.free;
    final e = entitlement;
    if (e == null) return PlanKind.monthly;
    if (e.billingIssue) return PlanKind.billingIssue;
    if (e.isTrial) return PlanKind.trial;
    return e.isYearly ? PlanKind.yearly : PlanKind.monthly;
  }

  /// Whole days left in the trial (at least 1 while it runs), or null.
  int? trialDaysLeft(DateTime now) {
    final end = entitlement?.expiresAt;
    if (plan != PlanKind.trial || end == null) return null;
    final hours = end.difference(now).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  factory ProStatus.fromJson(Map<String, dynamic> json) {
    final isPro = json['pro'] as bool? ?? false;
    final plan = json['plan'];
    final items = json['items'] as Map<String, dynamic>? ?? const {};
    return ProStatus(
      isPro: isPro,
      entitlement: plan is Map<String, dynamic> ? ProEntitlement.fromJson(plan, isActive: isPro) : null,
      scan: Quota.fromJson(json['scan'] as Map<String, dynamic>?),
      chat: Quota.fromJson(json['chat'] as Map<String, dynamic>?),
      items: {
        for (final item in LimitedItem.values)
          if (items[item.name] is Map<String, dynamic>) item: ItemUsage.fromJson(items[item.name]),
      },
    );
  }

  /// This status with the store's word on the subscription, which arrives
  /// the moment a purchase completes, before the webhook has updated the
  /// server. Pro limits are lifted on screen right away; the server lifts
  /// them for real a few seconds later.
  ///
  /// An inactive store entitlement changes nothing: the server already
  /// stops Pro at `active_until`, without waiting for a webhook.
  ProStatus withStoreEntitlement(ProEntitlement store) {
    if (!store.isActive) return this;
    return ProStatus(
      isPro: true,
      entitlement: store,
      scan: Quota(used: scan.used),
      chat: chat,
      items: {for (final e in items.entries) e.key: ItemUsage(count: e.value.count)},
    );
  }

  ProStatus copyWith({bool? isPro, ProEntitlement? entitlement}) => ProStatus(
        isPro: isPro ?? this.isPro,
        entitlement: entitlement ?? this.entitlement,
        scan: scan,
        chat: chat,
        items: items,
      );

  @override
  List<Object?> get props => [isPro, entitlement, scan, chat, items];
}
