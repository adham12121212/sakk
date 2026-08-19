
import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../entities/notification_enitiy.dart';
import '../notification_repo/notification_repo.dart';

abstract class GetNotificationsUseCase {
    Future<Either<Failure, List<NotificationEntity>>> call(String userId);

}

class GetNotificationUseCaseImpl implements GetNotificationsUseCase{
    final NotificationRepo notificationRepo;
    GetNotificationUseCaseImpl({required this.notificationRepo});

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(String userId) {
    return notificationRepo.getNotifications(userId);
  }

}

