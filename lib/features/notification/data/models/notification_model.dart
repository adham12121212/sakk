import '../../domain/entities/notification_enitiy.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.subtitle,
    required super.type,
    required super.createdAt,
    super.isRead,
    super.productId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      type: NotificationType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      productId: json['product_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'product_id': productId,
    };
  }

  /// Row payload for inserting a brand-new notification — no `id` or
  /// `created_at`, since the DB should generate both.
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'is_read': isRead,
      if (productId != null) 'product_id': productId,
    };
  }
}