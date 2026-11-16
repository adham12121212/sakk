import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_icons.dart';

void showInvoicePreviewDialog(BuildContext context, String? imageUrl) {
  if (imageUrl == null) return;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  AppIcons.brokenImage,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40.h,
            right: 20.w,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(AppIcons.close, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    ),
  );
}
