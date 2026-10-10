import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';

/// Home summary tile: tinted icon square, large number, muted label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 14),
          Text(value, style: textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
