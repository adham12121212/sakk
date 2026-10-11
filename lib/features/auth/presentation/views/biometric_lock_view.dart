import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';
import '../cubit/auth_cubit.dart';
import '../../../../core/constant/app_colors.dart';

class BiometricLockView extends StatefulWidget {
  const BiometricLockView({super.key});

  @override
  State<BiometricLockView> createState() => _BiometricLockViewState();
}

class _BiometricLockViewState extends State<BiometricLockView>
    with WidgetsBindingObserver {
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_authenticating && mounted) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating || !mounted) return;
    setState(() => _authenticating = true);

    final l10n = AppLocalizations.of(context)!;
    final success = await getIt<BiometricAuthService>().authenticate(
      reason: l10n.biometricUnlockReason,
    );

    if (!mounted) return;
    setState(() => _authenticating = false);

    if (success) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _usePasswordInstead() async {
    // Through AuthCubit so the previous session's cached data is cleared
    // too; the lock stays on since the same person is signing back in.
    final authCubit = getIt<AuthCubit>();
    await authCubit.signOut(keepBiometricLock: true);
    await authCubit.close();
    if (!mounted) return;
    context.go(AppRoutes.signin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104.w,
                  height: 104.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.brandGradientColors,
                    ),
                    borderRadius: BorderRadius.circular(32.r),
                    boxShadow: const [
                      BoxShadow(color: Color(0x404A5CFA), blurRadius: 28, offset: Offset(0, 12)),
                    ],
                  ),
                  child: Icon(AppIcons.fingerprint, size: 52.sp, color: Colors.white),
                ),
                SizedBox(height: 24.h),
                Text(
                  l10n.appLockedTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.appLockedSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _authenticating ? null : _unlock,
                    icon: _authenticating
                        ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(AppIcons.fingerprint),
                    label: Text(l10n.unlockButton),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: _authenticating ? null : _usePasswordInstead,
                  child: Text(l10n.usePasswordInstead),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}