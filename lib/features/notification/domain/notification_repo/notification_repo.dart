import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../entities/notification_enitiy.dart';

abstract class NotificationRepo {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String userId);
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId);
  Future<Either<Failure, void>> deleteNotification(String notificationId);
  Future<Either<Failure, void>> addNotification({
    required String userId,
    required String title,
    required String subtitle,
    required NotificationType type,
    String? productId,
  });
}