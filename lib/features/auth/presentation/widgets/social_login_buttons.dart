import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class SocialLoginButtons extends StatelessWidget {
  final bool showBiometric;
  const SocialLoginButtons({super.key, this.showBiometric = true});

  void _showComingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(thickness: 1, color: AppColors.grey)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(l10n.orContinueWith, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(child: Divider(thickness: 1, color: AppColors.grey)),
          ],
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon(context),
                icon: Icon(Icons.apple, color: AppColors.primary),
                label: Text(l10n.apple, style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showComingSoon(context),
                icon: Icon(Icons.g_mobiledata, color: AppColors.primary, size: 25.w),
                label: Text(l10n.google, style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        if (showBiometric) ...[
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: Icon(Icons.fingerprint, color: AppColors.primary),
              label: Text(l10n.signInWithBiometrics, style: TextStyle(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ],
      ],
    );
  }
}