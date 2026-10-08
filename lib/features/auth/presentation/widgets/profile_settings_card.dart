import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/auth/presentation/widgets/semented_toggle.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/locale_controller/locale_controller.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';


class ProfileSettingsCard extends StatefulWidget {
  const ProfileSettingsCard({super.key});

  @override
  State<ProfileSettingsCard> createState() => _ProfileSettingsCardState();
}

class _ProfileSettingsCardState extends State<ProfileSettingsCard> {
  final _biometricService = getIt<BiometricAuthService>();

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _loadingBiometricState = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await _biometricService.isAvailable;
    final enabled = await _biometricService.isEnabled;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _loadingBiometricState = false;
    });
  }

  Future<void> _onBiometricToggle(bool value) async {
    final l10n = AppLocalizations.of(context)!;

    if (!_biometricAvailable) {
      AppSnackBar.error(context, l10n.biometricNotAvailable);
      return;
    }

    if (value) {
      // Require a successful scan before turning this on — otherwise a
      // user with no biometrics actually enrolled could lock themselves
      // out on next launch with no way back in except uninstalling.
      final confirmed = await _biometricService.authenticate(
        reason: l10n.biometricConfirmEnableReason,
      );
      if (!confirmed || !mounted) return;
    }

    await _biometricService.setEnabled(value);
    if (!mounted) return;
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = getIt<LocaleController>();
    final themeController = getIt<ThemeController>();

    return ListenableBuilder(
      listenable: Listenable.merge([localeController, themeController]),
      builder: (context, _) {
        return Column(
          children: [
            _SettingsRow(
              icon: Icons.language_rounded,
              label: l10n.language,
              child: SegmentedToggle<String>(
                options: const {'en': 'EN', 'ar': 'AR'},
                selected: localeController.value.languageCode,
                onChanged: (code) => localeController.setLocale(Locale(code)),
              ),
            ),
            _SettingsRow(
              icon: Icons.brightness_6_rounded,
              label: l10n.theme,
              child: SegmentedToggle<ThemeMode>(
                options: {
                  ThemeMode.light: l10n.themeLight,
                  ThemeMode.dark: l10n.themeDark,
                  ThemeMode.system: l10n.themeAuto,
                },
                selected: themeController.value,
                onChanged: (mode) => themeController.setThemeMode(mode),
              ),
            ),
            _SettingsRow(
              icon: Icons.fingerprint_rounded,
              label: l10n.biometricLogin,
              isLast: true,
              child: _loadingBiometricState
                  ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
                  : Switch.adaptive(
                value: _biometricEnabled,
                activeColor: AppColors.primary,
                onChanged: _onBiometricToggle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.child,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(AppSizes.s16),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSizes.icon18, color: AppColors.primary),
          ),
          SizedBox(width: AppSizes.s12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14.sp,
                  fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
