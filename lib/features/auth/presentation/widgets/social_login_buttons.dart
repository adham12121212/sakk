import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/constant/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
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
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(l10n.orContinueWith, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
        SizedBox(height: 24.h),

        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final busy = state is AuthLoading;
            final colorScheme = Theme.of(context).colorScheme;
            return SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                // Disabled while any sign-in is running, so it can't fire twice.
                onPressed: busy ? null : () => context.read<AuthCubit>().signInWithGoogle(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline, width: 1.2),
                ),
                icon: Image.asset('assets/icons/google.png', width: 22, height: 22),
                label: Text(l10n.google, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ],
    );
  }
}