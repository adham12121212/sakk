import 'package:flutter/material.dart';
import 'package:sakk/features/scan/presentation/widgets/processing_field_spec.dart';

import 'shimmer_shape.dart';


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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: revealed ? const Color(0xFFDCFCE7) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
                ? const Icon(
              Icons.check_circle,
              key: ValueKey('check'),
              color: Color(0xFF22C55E),
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