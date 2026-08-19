import 'package:flutter/material.dart';

import '../../domain/entities/notification_enitiy.dart';

class NotificationTypeIcon extends StatelessWidget {
  final NotificationType type;
  const NotificationTypeIcon({super.key, required this.type});

  static const Map<NotificationType, (IconData, Color)> _config = {
    NotificationType.warning: (Icons.warning_amber_rounded, Colors.orange),
    NotificationType.success: (Icons.check_circle_outline, Colors.green),
    NotificationType.info: (Icons.auto_awesome, Colors.blue),
    NotificationType.error: (Icons.error_outline, Colors.red),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _config[type]!;
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withValues(alpha: 0.13),
      child: Center(child: Icon(icon, color: color, size: 22)),
    );
  }
}