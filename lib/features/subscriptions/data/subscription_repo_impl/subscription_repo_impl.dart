import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
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

class SubscriptionRepoImpl implements SubscriptionRepo {
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

  /// Runs [action] online, mapping exceptions to failures the same way the
  /// products repo does. [operation] names it in the logs.
  Future<Either<Failure, T>> _online<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure(NetworkFailure.noConnectionMessage));
    }
    try {
      return Right(await action());
    } on ServerException catch (e, st) {
      _logger.error('Server error during $operation', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error(
        'Unexpected error during $operation',
        error: e,
        stackTrace: st,
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Loads with [load] and saves the result with [save]. Offline or on a
  /// failed load, serves the last list saved on this device, if there is one.
  Future<Either<Failure, List<E>>> _loadWithCache<E, M extends E>({
    required String operation,
    required Future<List<M>> Function() load,
    required Future<void> Function(List<M>) save,
    required Future<List<M>?> Function() cached,
  }) async {
    final result = await _online<List<M>>(operation, load);
    return result.fold(
      (failure) async {
        try {
          final rows = await cached();
          // Re-wrap so the list is a List<E> at runtime, not List<M>
          // (see the comment in ProductRepoImpl.getProducts).
          if (rows != null) return Right(List<E>.from(rows));
        } catch (e) {
          _logger.warning(
            'Reading the offline cache for $operation failed',
            data: {'error': '$e'},
          );
        }
        return Left(failure);
      },
      (rows) async {
        try {
          await save(rows);
        } catch (e) {
          _logger.warning(
            'Saving the offline cache for $operation failed',
            data: {'error': '$e'},
          );
        }
        return Right(List<E>.from(rows));
      },
    );
  }

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
    return _loadWithCache<CatalogService, CatalogServiceModel>(
      operation: 'getCatalog',
      load: _dataSource.getCatalog,
      save: _localDataSource.cacheCatalog,
      cached: _localDataSource.getCachedCatalog,
    );
  }

  @override
  Future<Either<Failure, List<UserSubscription>>> getSubscriptions() {
    return _loadWithCache<UserSubscription, UserSubscriptionModel>(
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
    return _online('addSubscription', () async {
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
    return _online('updateSubscription', () async {
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
    return _online('deleteSubscription', () async {
      await _dataSource.deleteSubscription(id);
      await _updateCache(
        (current) => current.where((s) => s.id != id).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, ScannedSubscription>> extractSubscription({
    String? imagePath,
    String? text,
    List<String> knownServices = const [],
  }) {
    return _online(
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
