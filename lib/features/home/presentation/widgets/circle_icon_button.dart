import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/localized_number.dart';


/// Round icon-only button. The visible circle stays 40.w, but the tap area is
/// at least 48×48 and [semanticLabel] is announced by screen readers (and
/// shown as a long-press tooltip), since there's no visible text.
///
/// Badges: [badgeCount] > 0 shows a numbered Material 3 badge (locale digits,
/// capped at "9+"); otherwise [showBadge] shows a plain dot. Badge text is
/// excluded from semantics, so put the count in [semanticLabel] too.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
    this.color = AppColors.black,
  });

  static const double _minTapTarget = 48;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool showBadge;
  final int badgeCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diameter = 40.w;

    final circle = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 28.h, color: color),
    );

    final Widget badged;
    if (badgeCount > 0) {
      badged = Badge(
        label: Text(formatBadgeCount(Localizations.localeOf(context), badgeCount)),
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        child: circle,
      );
    } else if (showBadge) {
      badged = Badge(
        backgroundColor: AppColors.error,
        smallSize: 10.w,
        child: circle,
      );
    } else {
      badged = circle;
    }

    return Tooltip(
      message: semanticLabel,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticLabel,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _minTapTarget,
              minHeight: _minTapTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: badged,
            ),
          ),
        ),
      ),
    );
  }
}
