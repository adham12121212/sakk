import 'notification_message.dart';

enum NotificationType { success, warning, info, error }

class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String subtitle;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? productId;

  /// What it says, to show in the current language; null on rows made
  /// before it was saved, which show [title] and [subtitle] as stored.
  final NotificationMessage? message;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.productId,
    this.message,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? subtitle,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? productId,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      productId: productId ?? this.productId,
      message: message,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NotificationEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
