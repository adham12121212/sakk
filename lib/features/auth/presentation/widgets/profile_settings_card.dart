import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/auth/presentation/widgets/semented_toggle.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/locale_controller/locale_controller.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../core/service/reminder_controller.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../../core/theme/theme_controller.dart';
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

  /// Saves the new reminder lead time and moves every pending reminder to it.
  Future<void> _onReminderChanged(int days) async {
    await getIt<ReminderController>().setDays(days);
    await getIt<WarrantyNotificationService>().rescheduleAll(getIt<ProductsCubit>().state.products);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = getIt<LocaleController>();
    final themeController = getIt<ThemeController>();
    final reminderController = getIt<ReminderController>();

    return ListenableBuilder(
      listenable: Listenable.merge([localeController, themeController, reminderController]),
      builder: (context, _) {
        // One white card, rows separated by hairlines (iOS-settings style).
        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
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
              // Three options: full width under the label so the label is
              // never squeezed on narrow screens.
              stacked: true,
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
              icon: Icons.notifications_active_outlined,
              label: l10n.warrantyReminder,
              stacked: true,
              child: SegmentedToggle<int>(
                options: {
                  90: l10n.reminder3Months,
                  30: l10n.reminder1Month,
                  7: l10n.reminder1Week,
                  1: l10n.reminder1Day,
                },
                selected: reminderController.value,
                onChanged: _onReminderChanged,
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
                onChanged: _onBiometricToggle,
              ),
            ),
          ],
          ),
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
    this.stacked = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final bool isLast;

  /// Puts [child] full width under the label instead of at the row's end.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final header = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: textTheme.titleSmall?.copyWith(fontSize: 15))),
        if (!stacked) child,
      ],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: stacked
              ? Column(
                  children: [
                    header,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: child),
                  ],
                )
              : header,
        ),
        if (!isLast) Divider(height: 1, indent: 66, endIndent: 16, color: colorScheme.outlineVariant),
      ],
    );
  }
}
