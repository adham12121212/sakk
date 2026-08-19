import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class ForgotPasswordButton extends StatelessWidget {
  const ForgotPasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: () {
          // TODO(adham): Navigate to forgot password
        },
        child: Text(l10n.forgotPassword,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),),
      ),
    );
  }
}