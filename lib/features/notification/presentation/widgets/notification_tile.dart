import 'package:flutter/material.dart';
import 'package:sakk/core/constant/app_colors.dart';

import '../../domain/entities/notification_enitiy.dart';
import 'notification_type_icon.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(49),
        borderRadius: BorderRadius.circular(20)
      ),
      child: ListTile(
        onTap: onTap,
        leading: NotificationTypeIcon(type: notification.type),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.subtitle),
            const SizedBox(height: 2),
            Text(
              _timeAgo(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color:  AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }


  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}