import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/constant/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';

class SocialLoginButtons extends StatelessWidget {
  final bool showBiometric;
  const SocialLoginButtons({super.key, this.showBiometric = true});

  void _showComingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  Future<void> _handleBiometricSignIn(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      AppSnackBar.error(context, l10n.biometricRequiresActiveSession);
      return;
    }

    final biometricService = getIt<BiometricAuthService>();
    if (!await biometricService.isEnabled) {
      if (!context.mounted) return;
      AppSnackBar.error(context, l10n.biometricNotEnabledYet);
      return;
    }

    final success = await biometricService.authenticate(
      reason: l10n.biometricUnlockReason,
    );
    if (success && context.mounted) {
      context.go(AppRoutes.home);
    }
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
                child:GestureDetector(
                  onTap: () => context.read<AuthCubit>().signInWithGoogle(),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.primary,
                      width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/icons/google.png', width: 25.w),
                        SizedBox(width: 10.w),
                        Text(l10n.google, style: TextStyle(color: AppColors.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600)
                        ),
                      ],
                    ),
                  ),
                )
            )
              ],
            ),


      ],
    );
  }
}