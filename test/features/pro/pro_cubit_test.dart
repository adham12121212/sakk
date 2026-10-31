import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/pro/data/pro_status_data_source.dart';
import 'package:sakk/features/pro/data/purchases_gateway.dart';
import 'package:sakk/features/pro/domain/entities/pro_status.dart';
import 'package:sakk/features/pro/domain/pro_limit.dart';
import 'package:sakk/features/pro/presentation/cubit/paywall_cubit.dart';
import 'package:sakk/features/pro/presentation/cubit/pro_cubit.dart';

const _free = ProStatus(
  scan: Quota(used: 3, limit: 3, remaining: 0),
  items: {LimitedItem.products: ItemUsage(count: 5, limit: 5)},
);
const _pro = ProStatus(
  isPro: true,
  entitlement: ProEntitlement(isActive: true, productId: 'sakk_pro:monthly'),
  scan: Quota(used: 3),
  items: {LimitedItem.products: ItemUsage(count: 5)},
);

class _Server implements ProStatusDataSource {
  ProStatus status = _free;
  int calls = 0;

  /// Fails like a missing function or no connection.
  bool fail = false;

  @override
  Future<ProStatus> getStatus() async {
    calls++;
    if (fail) throw Exception('PGRST202');
    return status;
  }
}

class FakeStore implements PurchasesGateway {
  final changes = StreamController<ProEntitlement>.broadcast();
  final logins = <String>[];
  int logouts = 0;
  ProEntitlement purchaseResult = const ProEntitlement(
    isActive: true,
    productId: 'sakk_pro:yearly',
  );
  bool cancel = false;

  bool available = true;

  @override
  bool get isAvailable => available;
  @override
  Future<void> init() async {}
  @override
  Future<void> logIn(String userId) async => logins.add(userId);
  @override
  Future<void> logOut() async => logouts++;
  @override
  Stream<ProEntitlement> get entitlementChanges => changes.stream;
  @override
  Future<ProEntitlement?> currentEntitlement() async => null;
  @override
  Future<ProOffer?> loadOffer() async => const ProOffer(
    monthly: ProPackage(
      id: 'm',
      isYearly: false,
      price: 29,
      priceString: 'EGP 29',
      currencyCode: 'EGP',
    ),
    yearly: ProPackage(
      id: 'y',
      isYearly: true,
      price: 260,
      priceString: 'EGP 260',
      currencyCode: 'EGP',
      freeTrialDays: 7,
    ),
  );
  @override
  Future<ProEntitlement> purchase(ProPackage package) async {
    if (cancel) throw const PurchaseCancelledException();
    return purchaseResult;
  }

  @override
  Future<ProEntitlement> restore() async =>
      const ProEntitlement(isActive: false);
  @override
  Future<Uri> managementUri({String? productId}) async =>
      Uri.parse('https://play.google.com');
}

class NoLog implements AppLogger {
  @override
  void debug(String message, {Map<String, dynamic>? data}) {}
  @override
  void info(String message, {Map<String, dynamic>? data}) {}
  @override
  void warning(String message, {Map<String, dynamic>? data}) {}
  @override
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {}
}

void main() {
  late _Server server;
  late FakeStore store;
  late StreamController<String?> users;
  late StreamController<void> usage;
  late StreamController<void> resumed;
  late ProCubit cubit;

  setUp(() {
    server = _Server();
    store = FakeStore();
    users = StreamController<String?>();
    usage = StreamController<void>.broadcast();
    resumed = StreamController<void>.broadcast();
    cubit = ProCubit(
      server,
      store,
      userIdChanges: users.stream,
      logger: NoLog(),
      usageChanged: usage.stream,
      appResumed: resumed.stream,
      refreshDebounce: Duration.zero,
      serverCatchUpInterval: Duration.zero,
    );
  });

  tearDown(() => cubit.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 10));

  test('signing in logs in to the store and loads the plan', () async {
    users.add('user-1');
    await settle();
    expect(store.logins, ['user-1']);
    expect(cubit.state.hasLoadedOnce, isTrue);
    expect(cubit.canAdd(LimitedItem.products), isFalse);
    expect(cubit.canUse(QuotaType.scan), isFalse);
    expect(cubit.canAdd(LimitedItem.installments), isTrue);
  });

  test('signing out logs out of the store and forgets the plan', () async {
    users.add('user-1');
    await settle();
    users.add(null);
    await settle();
    expect(store.logouts, 1);
    expect(cubit.state, const ProState());
  });

  test('a purchase shows Pro at once, then waits for the server', () async {
    users.add('user-1');
    await settle();

    // The webhook hasn't reached the server yet.
    store.changes.add(
      const ProEntitlement(isActive: true, productId: 'sakk_pro:yearly'),
    );
    await settle();
    expect(cubit.isPro, isTrue);
    expect(cubit.state.status.plan, PlanKind.yearly);
    expect(cubit.canAdd(LimitedItem.products), isTrue);

    // A server read that still says free keeps the store's Pro on screen.
    await cubit.refresh();
    expect(cubit.isPro, isTrue);

    server.status = _pro;
    await cubit.applyPurchase(
      const ProEntitlement(isActive: true, productId: 'sakk_pro:monthly'),
    );
    expect(cubit.state.status, _pro);
  });

  test(
    'a failed load is reported instead of loading forever, and a retry recovers',
    () async {
      server.fail = true;
      users.add('user-1');
      await settle();
      expect(cubit.state.hasLoadedOnce, isFalse);
      expect(cubit.state.loadFailed, isTrue);
      // Nothing is blocked on the client while the plan is unknown.
      expect(cubit.canAdd(LimitedItem.products), isTrue);

      server.fail = false;
      await cubit.refresh();
      expect(cubit.state.hasLoadedOnce, isTrue);
      expect(cubit.state.loadFailed, isFalse);
    },
  );

  test('usage changes re-read the counters', () async {
    users.add('user-1');
    await settle();
    final before = server.calls;
    usage.add(null);
    await settle();
    expect(server.calls, before + 1);
  });

  test('coming back to the app picks up Pro granted on the server', () async {
    users.add('user-1');
    await settle();
    expect(cubit.isPro, isFalse);

    server.status = _pro;
    resumed.add(null);
    await settle();
    expect(cubit.isPro, isTrue);
  });

  test(
    'expiry: the server says free again and nothing is kept from before',
    () async {
      server.status = _pro;
      users.add('user-1');
      await settle();
      expect(cubit.isPro, isTrue);

      server.status = _free;
      await cubit.refresh();
      expect(cubit.isPro, isFalse);
      expect(cubit.state.status.plan, PlanKind.free);
    },
  );

  group('PaywallCubit', () {
    test('loads both plans with yearly picked; purchase unlocks Pro', () async {
      users.add('user-1');
      await settle();
      final paywall = PaywallCubit(store, cubit, NoLog());
      addTearDown(paywall.close);

      await paywall.load();
      expect(paywall.state.yearlySelected, isTrue);
      expect(paywall.state.selected?.freeTrialDays, 7);
      expect(paywall.state.offer?.yearlySavingsPercent, 25);

      await paywall.purchase();
      expect(paywall.state.message, PaywallMessage.purchased);
      await settle();
      expect(cubit.isPro, isTrue);
    });

    test('backing out of the store sheet is not an error', () async {
      final paywall = PaywallCubit(store, cubit, NoLog());
      addTearDown(paywall.close);
      await paywall.load();
      store.cancel = true;
      await paywall.purchase();
      expect(paywall.state.message, isNull);
      expect(paywall.state.isPurchasing, isFalse);
    });

    test('restore with nothing to restore says so', () async {
      final paywall = PaywallCubit(store, cubit, NoLog());
      addTearDown(paywall.close);
      await paywall.restore();
      expect(paywall.state.message, PaywallMessage.nothingToRestore);
    });
  });
}
