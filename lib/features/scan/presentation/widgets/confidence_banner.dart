import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ConfidenceBanner extends StatelessWidget {
  const ConfidenceBanner({super.key, required this.confidence});

  final double confidence;

  static const _highThreshold = 0.8;
  static const _mediumThreshold = 0.5;

  @override
  Widget build(BuildContext context) {
    final level = _levelFor(confidence);
    final percent = (confidence * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: level.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: level.foreground.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(level.icon, color: level.foreground, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: level.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Confidence Score: '),
                      TextSpan(
                        text: '$percent%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (level.subtext != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    level.subtext!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: level.foreground.withOpacity(0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ConfidenceLevel _levelFor(double confidence) {
    if (confidence >= _highThreshold) {
      return const _ConfidenceLevel(
        foreground: Color(0xFF15803D),
        background: Color(0xFFDCFCE7),
        icon: Icons.check_circle_rounded,
      );
    }
    if (confidence >= _mediumThreshold) {
      return const _ConfidenceLevel(
        foreground: Color(0xFF92400E),
        background: Color(0xFFFEF3C7),
        icon: Icons.warning_amber_rounded,
        subtext: 'Please double-check the fields below.',
      );
    }
    return const _ConfidenceLevel(
      foreground: Color(0xFF991B1B),
      background: Color(0xFFFEE2E2),
      icon: Icons.error_outline_rounded,
      subtext:
      "We weren't fully confident reading this receipt — please double-check every field.",
    );
  }
}

class _ConfidenceLevel {
  const _ConfidenceLevel({
    required this.foreground,
    required this.background,
    required this.icon,
    this.subtext,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
  final String? subtext;
}