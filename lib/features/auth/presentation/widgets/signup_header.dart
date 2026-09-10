import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: IconButton(
              icon: const Icon(Icons.arrow_back,color: AppColors.primary,),
              onPressed: () => context.pop(),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text( l10n.createAccount,
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
              Text(l10n.joinSakkToday,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}