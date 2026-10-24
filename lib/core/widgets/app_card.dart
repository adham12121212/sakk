import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// White rounded card with the soft shadow of the "soft & airy" style (a
/// hairline border instead in dark mode). Pass [onTap] for an ink ripple
/// clipped to the card's shape.
///
/// Inside a [GroupedCard] it draws no card of its own, just its content
/// and ripple, so list tiles become rows of the group.
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
    if (_GroupRow.of(context)) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          // Cards inside the row's content are cards again.
          child: _GroupRow(
            isRow: false,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

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

/// Rows in one card with a hairline between them, the list style used
/// across the app. Each child that is an [AppCard] (most list tiles) draws
/// as a plain row.
class GroupedCard extends StatelessWidget {
  const GroupedCard({
    super.key,
    required this.children,
    this.dividerIndent = 68,
  });

  final List<Widget> children;

  /// Where the hairline starts, so it lines up with the rows' text.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      indent: dividerIndent,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) divider,
              _GroupRow(isRow: true, child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tells an [AppCard] whether it's a row of a [GroupedCard].
class _GroupRow extends InheritedWidget {
  const _GroupRow({required this.isRow, required super.child});

  final bool isRow;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupRow>()?.isRow ?? false;

  @override
  bool updateShouldNotify(_GroupRow old) => old.isRow != isRow;
}
