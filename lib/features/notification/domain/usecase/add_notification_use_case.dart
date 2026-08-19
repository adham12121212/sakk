import 'package:dartz/dartz.dart';

import '../../../../core/error/Failure.dart';
import '../entities/notification_enitiy.dart';
import '../notification_repo/notification_repo.dart';

abstract class AddNotificationUseCase {
  Future<Either<Failure, void>> call({
    required String userId,
    required String title,
    required String subtitle,
    required NotificationType type,
    String? productId,
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
  }) {
    return notificationRepo.addNotification(
      userId: userId,
      title: title,
      subtitle: subtitle,
      type: type,
      productId: productId,
    );
  }
}