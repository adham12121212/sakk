import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Top bar for the review screen: a back button plus a title/subtitle.
class ReviewHeader extends StatelessWidget {
  const ReviewHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Details',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Review and edit extracted data',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}