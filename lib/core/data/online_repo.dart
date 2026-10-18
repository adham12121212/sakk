import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../error/exceptions.dart';
import '../error/failure.dart';
import '../error/network_info.dart';
import '../logger/app_logger.dart';

/// Shared by repositories that write online only and read with an offline
/// fallback (subscriptions, installments).
mixin OnlineRepo {
  NetworkInfo get networkInfo;
  AppLogger get logger;

  /// Runs [action] online, mapping exceptions to failures the same way the
  /// products repo does. [operation] names it in the logs.
  @protected
  Future<Either<Failure, T>> online<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(NetworkFailure.noConnectionMessage));
    }
    try {
      return Right(await action());
    } on ServerException catch (e, st) {
      logger.error('Server error during $operation', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      logger.error(
        'Unexpected error during $operation',
        error: e,
        stackTrace: st,
      );
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Loads with [load] and saves the result with [save]. Offline or on a
  /// failed load, serves the last list saved on this device, if there is one.
  @protected
  Future<Either<Failure, List<E>>> loadWithCache<E, M extends E>({
    required String operation,
    required Future<List<M>> Function() load,
    required Future<void> Function(List<M>) save,
    required Future<List<M>?> Function() cached,
  }) async {
    final result = await online<List<M>>(operation, load);
    return result.fold(
      (failure) async {
        try {
          final rows = await cached();
          // Re-wrap so the list is a List<E> at runtime, not List<M>
          // (see the comment in ProductRepoImpl.getProducts).
          if (rows != null) return Right(List<E>.from(rows));
        } catch (e) {
          logger.warning(
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
          logger.warning(
            'Saving the offline cache for $operation failed',
            data: {'error': '$e'},
          );
        }
        return Right(List<E>.from(rows));
      },
    );
  }
}
