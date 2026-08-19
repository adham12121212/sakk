import 'package:dartz/dartz.dart';
import 'package:sakk/core/error/Exceptions.dart';
import 'package:sakk/core/error/Failure.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/notification/domain/entities/notification_enitiy.dart';

import '../../domain/notification_repo/notification_repo.dart';
import '../notification_data_source/notification_data_source.dart';

class NotificationRepoImpl implements NotificationRepo {
  final NotificationDataSource _dataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;

  NotificationRepoImpl(this._dataSource, this._networkInfo, this._logger);

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final notifications = await _dataSource.getNotifications(userId);
      return Right(notifications);
    } on ServerException catch (e, st) {
      _logger.error('Server error during getNotifications', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Unexpected error during getNotifications', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await _dataSource.markNotificationAsRead(notificationId);
      return const Right(null);
    } on ServerException catch (e, st) {
      _logger.error('Server error during markNotificationAsRead', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Unexpected error during markNotificationAsRead', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await _dataSource.deleteNotification(notificationId);
      return const Right(null);
    } on ServerException catch (e, st) {
      _logger.error('Server error during deleteNotification', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Unexpected error during deleteNotification', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addNotification({
    required String userId,
    required String title,
    required String subtitle,
    required NotificationType type,
    String? productId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await _dataSource.createNotification({
        'user_id': userId,
        'title': title,
        'subtitle': subtitle,
        'type': type.name,
        'is_read': false,
        if (productId != null) 'product_id': productId,
      });
      return const Right(null);
    } on ServerException catch (e, st) {
      _logger.error('Server error during addNotification', error: e, stackTrace: st);
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Unexpected error during addNotification', error: e, stackTrace: st);
      return Left(UnknownFailure(e.toString()));
    }
  }
}