import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import 'package:sakk/features/scan/presentation/widgets/processing_field_spec.dart';

import 'shimmer_shape.dart';
import '../../../../core/theme/app_icons.dart';

class ProcessingFieldTile extends StatelessWidget {
  const ProcessingFieldTile({
    super.key,
    required this.spec,
    required this.value,
    required this.revealed,
    required this.shimmerAnimation,
  });

  final ProcessingFieldSpec spec;
  final String? value;
  final bool revealed;
  final Animation<double> shimmerAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: palette.cardShadow,
        // Revealed fields get a soft green edge.
        border: revealed
            ? Border.all(color: palette.success.withValues(alpha: 0.35))
            : (isDark ? Border.all(color: colorScheme.outline) : null),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: revealed
                      ? Text(
                          value ?? '—',
                          key: const ValueKey('value'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : ShimmerBar(
                          key: const ValueKey('shimmer'),
                          width: spec.skeletonWidth,
                          animation: shimmerAnimation,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: revealed
                ? Icon(
                    AppIcons.successFilled,
                    key: ValueKey('check'),
                    color: palette.success,
                    size: 22,
                  )
                : ShimmerCircle(
                    key: const ValueKey('shimmer-icon'),
                    animation: shimmerAnimation,
                  ),
          ),
        ],
      ),
    );
  }
}
