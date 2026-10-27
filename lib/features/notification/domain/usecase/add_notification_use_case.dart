import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_entity.dart';
import '../notification_repo/notification_repo.dart';
import '../entities/notification_message.dart';

abstract class AddNotificationUseCase {
  Future<Either<Failure, void>> call({
    required String userId,
    required String title,
    required String subtitle,
    required NotificationType type,
    String? productId,
    NotificationMessage? message,
  });
}

class AddNotificationUseCaseImpl implements AddNotificationUseCase {
  final NotificationRepo notificationRepo;
  AddNotificationUseCaseImpl({required this.notificationRepo});

  @override
  Future<Either<Failure, void>> call({
    required String userId,
    required String title,
    required String subtitle,
    required NotificationType type,
    String? productId,
    NotificationMessage? message,
  }) {
    return notificationRepo.addNotification(
      userId: userId,
      title: title,
      subtitle: subtitle,
      type: type,
      productId: productId,
      message: message,
    );
  }
}
