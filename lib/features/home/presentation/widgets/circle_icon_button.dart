import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';


/// Round icon-only button. The visible circle stays 40.w, but the tap area is
/// at least 48×48 and [semanticLabel] is announced by screen readers (and
/// shown as a long-press tooltip), since there's no visible text.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.showBadge = false,
    this.color = AppColors.black,
  });

  static const double _minTapTarget = 48;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool showBadge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diameter = 40.w;

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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28.h, color: color),
                  ),
                  if (showBadge)
                    PositionedDirectional(
                      top: diameter * 0.2,
                      end: diameter * 0.25,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
