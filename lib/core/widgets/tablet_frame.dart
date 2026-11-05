import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/screen_scaling.dart';

/// Centres a phone-width screen on tablets. Does nothing on phones.
class TabletColumn extends StatefulWidget {
  const TabletColumn({super.key, required this.child});

  static const maxWidth = 600.0;

  final Widget child;

  @override
  State<TabletColumn> createState() => _TabletColumnState();
}

class _TabletColumnState extends State<TabletColumn> {
  // Keeps the screen's state when a resized window crosses the tablet width.
  final _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (!isTabletLayout(context)) return child;

    return ColoredBox(
      // Opaque, so the page underneath doesn't show during transitions.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = min(constraints.maxWidth, TabletColumn.maxWidth);
          final gutter = (constraints.maxWidth - width) / 2;
          final media = MediaQuery.of(context);
          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: MediaQuery(
                data: media.copyWith(
                  size: Size(width, constraints.maxHeight),
                  padding: _insideGutter(media.padding, gutter),
                  viewPadding: _insideGutter(media.viewPadding, gutter),
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  EdgeInsets _insideGutter(EdgeInsets insets, double gutter) => insets.copyWith(
    left: max(0, insets.left - gutter),
    right: max(0, insets.right - gutter),
  );
}

/// Shows a screen as a centred card on tablets, for sign-in and onboarding.
/// Does nothing on phones.
class TabletCard extends StatefulWidget {
  const TabletCard({super.key, required this.child});

  static const maxWidth = 480.0;
  static const maxHeight = 800.0;
  static const _margin = 24.0;

  final Widget child;

  @override
  State<TabletCard> createState() => _TabletCardState();
}

class _TabletCardState extends State<TabletCard> {
  // Keeps the screen's state when a resized window crosses the tablet width.
  final _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (!isTabletLayout(context)) return child;

    final media = MediaQuery.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    // The card itself stays clear of the system bars and the keyboard, so the
    // screen inside has no insets left to handle.
    final margin = EdgeInsets.fromLTRB(
      media.padding.left + TabletCard._margin,
      media.padding.top + TabletCard._margin,
      media.padding.right + TabletCard._margin,
      max(media.padding.bottom, media.viewInsets.bottom) + TabletCard._margin,
    );

    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            min(TabletCard.maxWidth, constraints.maxWidth - margin.horizontal),
            min(TabletCard.maxHeight, constraints.maxHeight - margin.vertical),
          );
          return Padding(
            padding: margin,
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F0F172A),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: MediaQuery(
                      data: media.copyWith(
                        size: size,
                        padding: EdgeInsets.zero,
                        viewPadding: EdgeInsets.zero,
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
