import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/exceptions.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/subscriptions/data/models/catalog_service_model.dart';
import 'package:sakk/features/subscriptions/data/models/user_subscription_model.dart';
import 'package:sakk/features/subscriptions/data/subscription_data_source/subscription_data_source.dart';
import 'package:sakk/features/subscriptions/data/subscription_data_source/subscription_local_data_source.dart';
import 'package:sakk/features/subscriptions/data/subscription_repo_impl/subscription_repo_impl.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/subscription_category.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';

import 'subscription_models_test.dart' show subscriptionRow;

class _FakeNetwork implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _SilentLogger implements AppLogger {
  @override
  void debug(String message, {Map<String, dynamic>? data}) {}
  @override
  void info(String message, {Map<String, dynamic>? data}) {}
  @override
  void warning(String message, {Map<String, dynamic>? data}) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {}
}

class _FakeRemote implements SubscriptionDataSource {
  List<UserSubscriptionModel> rows = [];
  bool fail = false;

  @override
  Future<List<UserSubscriptionModel>> getSubscriptions() async {
    if (fail) throw ServerException('boom');
    return rows;
  }

  @override
  Future<UserSubscriptionModel> addSubscription(Map<String, dynamic> insertJson) async {
    if (fail) throw ServerException('boom');
    return UserSubscriptionModel.fromJson({...insertJson, 'id': 'new', 'subscription_catalog': null});
  }

  @override
  Future<UserSubscriptionModel> updateSubscription(String id, Map<String, dynamic> updateJson) async =>
      UserSubscriptionModel.fromJson({...updateJson, 'id': id, 'subscription_catalog': null});

  @override
  Future<void> deleteSubscription(String id) async {}

  @override
  Future<List<CatalogServiceModel>> getCatalog() async => [];
}

class _MemoryCache implements SubscriptionLocalDataSource {
  List<UserSubscriptionModel>? subscriptions;
  List<CatalogServiceModel>? catalog;

  @override
  Future<List<UserSubscriptionModel>?> getCachedSubscriptions() async => subscriptions;
  @override
  Future<void> cacheSubscriptions(List<UserSubscriptionModel> s) async => subscriptions = s;
  @override
  Future<List<CatalogServiceModel>?> getCachedCatalog() async => catalog;
  @override
  Future<void> cacheCatalog(List<CatalogServiceModel> c) async => catalog = c;
  @override
  Future<void> clearAll() async {
    subscriptions = null;
    catalog = null;
  }
}

void main() {
  late _FakeNetwork network;
  late _FakeRemote remote;
  late _MemoryCache cache;
  late SubscriptionRepoImpl repo;

  final netflix = UserSubscriptionModel.fromJson(subscriptionRow());

  setUp(() {
    network = _FakeNetwork();
    remote = _FakeRemote();
    cache = _MemoryCache();
    repo = SubscriptionRepoImpl(remote, cache, network, _SilentLogger());
  });

  List<UserSubscription> rightOf(Either<Failure, List<UserSubscription>> r) =>
      r.getOrElse(() => fail('expected Right, got $r'));

  test('a successful load is saved for offline use', () async {
    remote.rows = [netflix];
    final result = await repo.getSubscriptions();
    expect(rightOf(result), [netflix]);
    expect(cache.subscriptions, [netflix]);
  });

  test('offline serves the cached list', () async {
    cache.subscriptions = [netflix];
    network.connected = false;
    expect(rightOf(await repo.getSubscriptions()), [netflix]);
  });

  test('offline with no cache is a network failure', () async {
    network.connected = false;
    final result = await repo.getSubscriptions();
    expect(result, const Left<Failure, List<UserSubscription>>(NetworkFailure(NetworkFailure.noConnectionMessage)));
  });

  test('a failed load falls back to the cache, or reports the server error', () async {
    remote.fail = true;
    expect((await repo.getSubscriptions()).isLeft(), isTrue);
    cache.subscriptions = [netflix];
    expect(rightOf(await repo.getSubscriptions()), [netflix]);
  });

  test('add, update and delete keep the cache in step, nearest renewal first', () async {
    cache.subscriptions = [netflix]; // renews 2026-11-01

    final added = await repo.addSubscription(
      customName: 'Gym',
      category: SubscriptionCategory.other,
      price: 500,
      currency: 'EGP',
      billingCycle: BillingCycle.monthly,
      nextRenewalDate: DateTime(2026, 12, 1),
    );
    expect(added.isRight(), isTrue);
    expect(cache.subscriptions!.map((s) => s.id), ['s1', 'new']);

    await repo.updateSubscription(
      id: 'new',
      customName: 'Gym',
      category: SubscriptionCategory.other,
      price: 550,
      currency: 'EGP',
      billingCycle: BillingCycle.monthly,
      nextRenewalDate: DateTime(2026, 10, 20),
    );
    expect(cache.subscriptions!.map((s) => s.id), ['new', 's1']);
    expect(cache.subscriptions!.first.price, 550);

    await repo.deleteSubscription('s1');
    expect(cache.subscriptions!.map((s) => s.id), ['new']);
  });

  test('writes need a connection', () async {
    network.connected = false;
    final result = await repo.deleteSubscription('s1');
    expect(result, const Left<Failure, void>(NetworkFailure(NetworkFailure.noConnectionMessage)));
  });
}
