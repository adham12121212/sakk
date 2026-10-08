import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sakk/core/constant/app_colors.dart';

import '../../../../l10n/app_localizations.dart';

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
              _timeAgo(context, notification.createdAt),
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


  String _timeAgo(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    // Older than a week: a short date in the app's locale.
    return DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(dateTime);
  }
}