import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/entities/pro_status.dart';

/// One plan on the paywall, with the store's localized price.
class ProPackage extends Equatable {
  const ProPackage({
    required this.id,
    required this.isYearly,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.pricePerMonthString,
    this.freeTrialDays,
    this.raw,
  });

  final String id;
  final bool isYearly;
  final double price;

  /// As the store formats it, e.g. "EGP 29.00".
  final String priceString;
  final String currencyCode;

  /// The price spread over a month, as the store formats it (yearly plan:
  /// "EGP 21.67"); null where the store doesn't give it.
  final String? pricePerMonthString;

  /// Length of the free trial this user can still get, or null.
  final int? freeTrialDays;

  /// The RevenueCat package, passed back to [PurchasesGateway.purchase].
  final Object? raw;

  @override
  List<Object?> get props => [
    id,
    isYearly,
    price,
    priceString,
    currencyCode,
    pricePerMonthString,
    freeTrialDays,
  ];
}

/// The paywall's two plans.
class ProOffer extends Equatable {
  const ProOffer({this.monthly, this.yearly});

  final ProPackage? monthly;
  final ProPackage? yearly;

  /// Whole percent saved by paying yearly instead of 12 months, from the
  /// store's real prices; null if it can't be worked out or is no saving.
  int? get yearlySavingsPercent {
    final m = monthly, y = yearly;
    if (m == null ||
        y == null ||
        m.price <= 0 ||
        m.currencyCode != y.currencyCode) {
      return null;
    }
    final percent = ((1 - y.price / (m.price * 12)) * 100).floor();
    return percent > 0 ? percent : null;
  }

  bool get isEmpty => monthly == null && yearly == null;

  @override
  List<Object?> get props => [monthly, yearly];
}

/// The user backed out of the store's purchase sheet: not an error.
class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();
}

/// The store took the order but the payment isn't through yet (cash at a
/// shop, carrier billing): Pro unlocks when the store confirms it.
class PurchasePendingException implements Exception {
  const PurchasePendingException();
}

/// The store, through RevenueCat. Behind an interface so tests and builds
/// without a RevenueCat key (the app then stays on the free plan) work.
abstract class PurchasesGateway {
  /// False without a key or on an unsupported platform; the paywall then
  /// says purchases aren't available.
  bool get isAvailable;

  Future<void> init();
  Future<void> logIn(String userId);
  Future<void> logOut();

  /// The store's view of Pro each time it changes (a purchase, a renewal
  /// noticed on launch...).
  Stream<ProEntitlement> get entitlementChanges;

  Future<ProEntitlement?> currentEntitlement();
  Future<ProOffer?> loadOffer();

  /// Throws [PurchaseCancelledException] if the user backs out and
  /// [PurchasePendingException] if the payment is still pending.
  Future<ProEntitlement> purchase(ProPackage package);
  Future<ProEntitlement> restore();

  /// Where the user manages or cancels the subscription (Google Play).
  Future<Uri> managementUri({String? productId});
}

class RevenueCatGateway implements PurchasesGateway {
  RevenueCatGateway({
    required String? androidApiKey,
    required String? iosApiKey,
    required this.packageName,
  }) : _apiKey = Platform.isAndroid
           ? androidApiKey
           : (Platform.isIOS ? iosApiKey : null);

  static const entitlementId = 'pro';

  final String? _apiKey;
  final String packageName;
  final _changes = StreamController<ProEntitlement>.broadcast();
  bool _configured = false;

  @override
  bool get isAvailable => _configured;

  @override
  Future<void> init() async {
    final key = _apiKey;
    if (key == null || key.isEmpty || _configured) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(key));
    Purchases.addCustomerInfoUpdateListener(
      (info) => _changes.add(_entitlementOf(info)),
    );
    _configured = true;
  }

  @override
  Future<void> logIn(String userId) async {
    if (!_configured) return;
    final result = await Purchases.logIn(userId);
    _changes.add(_entitlementOf(result.customerInfo));
  }

  @override
  Future<void> logOut() async {
    if (!_configured || await Purchases.isAnonymous) return;
    await Purchases.logOut();
  }

  @override
  Stream<ProEntitlement> get entitlementChanges => _changes.stream;

  @override
  Future<ProEntitlement?> currentEntitlement() async {
    if (!_configured) return null;
    return _entitlementOf(await Purchases.getCustomerInfo());
  }

  @override
  Future<ProOffer?> loadOffer() async {
    if (!_configured) return null;
    final offering = (await Purchases.getOfferings()).current;
    if (offering == null) return null;
    return ProOffer(
      monthly: _packageOf(offering.monthly, isYearly: false),
      yearly: _packageOf(offering.annual, isYearly: true),
    );
  }

  @override
  Future<ProEntitlement> purchase(ProPackage package) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package.raw! as Package),
      );
      return _entitlementOf(result.customerInfo);
    } on PlatformException catch (e) {
      switch (PurchasesErrorHelper.getErrorCode(e)) {
        case PurchasesErrorCode.purchaseCancelledError:
          throw const PurchaseCancelledException();
        case PurchasesErrorCode.paymentPendingError:
          throw const PurchasePendingException();
        default:
          rethrow;
      }
    }
  }

  @override
  Future<ProEntitlement> restore() async =>
      _entitlementOf(await Purchases.restorePurchases());

  @override
  Future<Uri> managementUri({String? productId}) async {
    if (_configured) {
      final url = (await Purchases.getCustomerInfo()).managementURL;
      if (url != null) return Uri.parse(url);
    }
    // Play's subscriptions page, opened on this app's subscription.
    final sku = productId?.split(':').first;
    return Uri.https('play.google.com', '/store/account/subscriptions', {
      'sku': ?sku,
      'package': packageName,
    });
  }

  ProEntitlement _entitlementOf(CustomerInfo info) {
    final e = info.entitlements.all[entitlementId];
    if (e == null) return const ProEntitlement(isActive: false);
    return ProEntitlement(
      isActive: e.isActive,
      // Google base plans: "sakk_pro:yearly".
      productId: e.productPlanIdentifier != null
          ? '${e.productIdentifier}:${e.productPlanIdentifier}'
          : e.productIdentifier,
      isTrial: e.periodType == PeriodType.trial,
      expiresAt: DateTime.tryParse(e.expirationDate ?? '')?.toLocal(),
      willRenew: e.willRenew,
      billingIssue: e.billingIssueDetectedAt != null,
    );
  }

  ProPackage? _packageOf(Package? package, {required bool isYearly}) {
    if (package == null) return null;
    final product = package.storeProduct;
    final trial = product.defaultOption?.freePhase?.billingPeriod;
    return ProPackage(
      id: package.identifier,
      isYearly: isYearly,
      price: product.price,
      priceString: product.priceString,
      currencyCode: product.currencyCode,
      pricePerMonthString: product.pricePerMonthString,
      freeTrialDays: trial == null ? null : _days(trial),
      raw: package,
    );
  }

  static int _days(Period period) => switch (period.unit) {
    PeriodUnit.day => period.value,
    PeriodUnit.week => period.value * 7,
    PeriodUnit.month => period.value * 30,
    PeriodUnit.year => period.value * 365,
    _ => period.value,
  };
}
