import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../l10n/app_localizations.dart';

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
    await Supabase.instance.client.auth.signOut();
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
                  width: 96.w,
                  height: 96.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fingerprint_rounded, size: 48.sp, color: AppColors.primary),
                ),
                SizedBox(height: 24.h),
                Text(
                  l10n.appLockedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.appLockedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: colorScheme.onSurface.withOpacity(0.6), height: 1.4),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: FilledButton.icon(
                    onPressed: _authenticating ? null : _unlock,
                    icon: _authenticating
                        ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.fingerprint_rounded),
                    label: Text(l10n.unlockButton),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
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