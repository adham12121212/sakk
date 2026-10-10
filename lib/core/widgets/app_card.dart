import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// White rounded card with the soft shadow of the "soft & airy" style (a
/// hairline border instead in dark mode). Pass [onTap] for an ink ripple
/// clipped to the card's shape.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radiusCard,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surface,
        borderRadius: shape,
        boxShadow: context.palette.cardShadow,
        border: isDark ? Border.all(color: colorScheme.outline) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
