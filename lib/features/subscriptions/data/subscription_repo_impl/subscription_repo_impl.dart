import 'package:dartz/dartz.dart';

import '../../../../core/data/online_repo.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/catalog_service.dart';
import '../../domain/entities/scanned_subscription.dart';
import '../../domain/entities/subscription_category.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/subscription_repo/subscription_repo.dart';
import '../models/catalog_service_model.dart';
import '../models/user_subscription_model.dart';
import '../subscription_data_source/subscription_data_source.dart';
import '../subscription_data_source/subscription_local_data_source.dart';

class SubscriptionRepoImpl with OnlineRepo implements SubscriptionRepo {
  final SubscriptionDataSource _dataSource;
  final SubscriptionLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  SubscriptionRepoImpl(
    this._dataSource,
    this._localDataSource,
    this._networkInfo,
    this._logger,
  );

  @override
  NetworkInfo get networkInfo => _networkInfo;
  @override
  AppLogger get logger => _logger;

  /// Applies [change] to the cached list (if any), so an add/edit/delete made
  /// online is also reflected the next time the app is offline.
  Future<void> _updateCache(
    List<UserSubscriptionModel> Function(List<UserSubscriptionModel> current)
    change,
  ) async {
    try {
      final current = await _localDataSource.getCachedSubscriptions();
      if (current == null) return;
      await _localDataSource.cacheSubscriptions(
        change(current)
          ..sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate)),
      );
    } catch (e) {
      _logger.warning(
        'Updating the offline subscription cache failed',
        data: {'error': '$e'},
      );
    }
  }

  @override
  Future<Either<Failure, List<CatalogService>>> getCatalog() {
    return loadWithCache<CatalogService, CatalogServiceModel>(
      operation: 'getCatalog',
      load: _dataSource.getCatalog,
      save: _localDataSource.cacheCatalog,
      cached: _localDataSource.getCachedCatalog,
    );
  }

  @override
  Future<Either<Failure, List<UserSubscription>>> getSubscriptions() {
    return loadWithCache<UserSubscription, UserSubscriptionModel>(
      operation: 'getSubscriptions',
      load: _dataSource.getSubscriptions,
      save: _localDataSource.cacheSubscriptions,
      cached: _localDataSource.getCachedSubscriptions,
    );
  }

  @override
  Future<Either<Failure, UserSubscription>> addSubscription({
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) {
    return online('addSubscription', () async {
      final saved = await _dataSource.addSubscription(
        UserSubscriptionModel.writeJson(
          catalogId: catalogId,
          customName: customName,
          planName: planName,
          category: category,
          price: price,
          currency: currency,
          billingCycle: billingCycle,
          nextRenewalDate: nextRenewalDate,
          paymentMethod: paymentMethod,
          notes: notes,
        ),
      );
      await _updateCache((current) => [saved, ...current]);
      return saved;
    });
  }

  @override
  Future<Either<Failure, UserSubscription>> updateSubscription({
    required String id,
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) {
    return online('updateSubscription', () async {
      final saved = await _dataSource.updateSubscription(
        id,
        UserSubscriptionModel.writeJson(
          catalogId: catalogId,
          customName: customName,
          planName: planName,
          category: category,
          price: price,
          currency: currency,
          billingCycle: billingCycle,
          nextRenewalDate: nextRenewalDate,
          paymentMethod: paymentMethod,
          notes: notes,
        ),
      );
      await _updateCache(
        (current) => [for (final s in current) s.id == id ? saved : s],
      );
      return saved;
    });
  }

  @override
  Future<Either<Failure, void>> deleteSubscription(String id) {
    return online('deleteSubscription', () async {
      await _dataSource.deleteSubscription(id);
      await _updateCache(
        (current) => current.where((s) => s.id != id).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, void>> updateRenewalDate(
    String id,
    DateTime nextRenewalDate, {
    int? renewalDay,
  }) {
    return online('updateRenewalDate', () async {
      await _dataSource.updateRenewalDate(
        id,
        nextRenewalDate,
        renewalDay: renewalDay,
      );
      await _updateCache(
        (current) => [
          for (final s in current)
            s.id == id
                ? UserSubscriptionModel.fromJson({
                    ...s.toCacheJson(),
                    'next_renewal_date': nextRenewalDate
                        .toIso8601String()
                        .split('T')
                        .first,
                    'renewal_day': ?renewalDay,
                  })
                : s,
        ],
      );
    });
  }

  @override
  Future<Either<Failure, ScannedSubscription>> extractSubscription({
    String? imagePath,
    String? text,
    List<String> knownServices = const [],
  }) {
    return online(
      'extractSubscription',
      () => _dataSource.extractSubscription(
        imagePath: imagePath,
        text: text,
        knownServices: knownServices,
      ),
    );
  }

  @override
  Future<void> clearCachedSubscriptions() async {
    try {
      await _localDataSource.clearAll();
    } catch (e) {
      _logger.warning(
        'Clearing the offline subscription cache failed',
        data: {'error': '$e'},
      );
    }
  }
}
