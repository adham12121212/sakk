import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


void showInvoicePreviewDialog(BuildContext context, String? imageUrl) {
  if (imageUrl == null) return;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 40.h,
            right: 20.w,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    ),
  );
}