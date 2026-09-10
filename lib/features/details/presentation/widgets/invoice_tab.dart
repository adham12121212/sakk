import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../l10n/app_localizations.dart';

class InvoiceTab extends StatelessWidget {
  const InvoiceTab({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrl == null) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        decoration: BoxDecoration(
            color:  colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 40.sp, color: colorScheme.onSurface.withOpacity(0.4)),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)!.noInvoiceAvailable,
                style: TextStyle(fontSize: 14.sp, color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InteractiveViewer(
        child: Image.network(
          imageUrl!,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            height: 240.h,
            color:  colorScheme.surfaceContainerHighest,
            child: Center(child: Icon(Icons.broken_image_outlined,
                size: 40.sp, color: colorScheme.onSurface.withOpacity(0.4))),
          ),
        ),
      ),
    );
  }
}