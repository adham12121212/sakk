import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../l10n/app_localizations.dart';

class ReviewHeader extends StatelessWidget {
  const ReviewHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;


    return Container(
      width: double.infinity,
      color: colorScheme.surface,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      child: Row(
        children: [
          // 40.w visible circle, 48×48 labelled tap area.
          Tooltip(
            message: l10n.back,
            excludeFromSemantics: true,
            child: Semantics(
              button: true,
              label: l10n.back,
              excludeSemantics: true,
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.verifyDetails, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                SizedBox(height: 2.h),
                Text(l10n.reviewAndEditExtractedData, style: TextStyle(fontSize: 13.sp, color: colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}