import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/notification_enitiy.dart';

/// Rounded tinted tile with the notification type's icon (palette colours, so
/// it adapts to dark mode).
class NotificationTypeIcon extends StatelessWidget {
  final NotificationType type;
  const NotificationTypeIcon({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color, background) = switch (type) {
      NotificationType.warning => (Icons.schedule_rounded, palette.warning, palette.warningContainer),
      NotificationType.success => (Icons.check_circle_outline_rounded, palette.success, palette.successContainer),
      NotificationType.info => (Icons.auto_awesome_rounded, colorScheme.primary, colorScheme.primaryContainer),
      NotificationType.error => (Icons.error_outline_rounded, palette.danger, palette.dangerContainer),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
