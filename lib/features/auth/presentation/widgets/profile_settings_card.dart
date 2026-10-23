import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/auth/presentation/widgets/segmented_toggle.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/locale_controller/locale_controller.dart';
import '../../../../core/service/biometric_auth_service.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/service/reminder_settings.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_icons.dart';

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

  /// "Warranties, Subscriptions, Installments", the ones that are on.
  String _remindersSummary(AppLocalizations l10n, ReminderSettings settings) {
    final on = [
      if (settings.warrantyEnabled) l10n.reminderWarranties,
      if (settings.subscriptionsEnabled) l10n.subscriptions,
      if (settings.installmentsEnabled) l10n.installments,
    ];
    return on.isEmpty ? l10n.remindersAllOff : on.join(l10n.listSeparator);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = getIt<LocaleController>();
    final themeController = getIt<ThemeController>();
    final reminderSettings = getIt<ReminderSettings>();

    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        themeController,
        reminderSettings,
      ]),
      builder: (context, _) {
        // One white card, rows separated by hairlines (iOS-settings style).
        return AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _SettingsRow(
                icon: AppIcons.language,
                label: l10n.language,
                child: SegmentedToggle<String>(
                  options: const {'en': 'EN', 'ar': 'AR'},
                  selected: localeController.value.languageCode,
                  onChanged: (code) => localeController.setLocale(Locale(code)),
                ),
              ),
              _SettingsRow(
                icon: AppIcons.theme,
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
              // Warranties, subscriptions and installments: their own screen.
              _SettingsRow(
                icon: AppIcons.reminder,
                label: l10n.reminders,
                subtitle: _remindersSummary(l10n, reminderSettings),
                onTap: () => context.push(AppRoutes.reminders),
                child: Icon(
                  AppIcons.chevronForward,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              _SettingsRow(
                icon: AppIcons.fingerprint,
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
    this.subtitle,
    this.onTap,
    this.isLast = false,
    this.stacked = false,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final String? subtitle;

  /// Makes the whole row tappable (e.g. to open a screen).
  final VoidCallback? onTap;
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.titleSmall?.copyWith(fontSize: 15)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (!stacked) child,
      ],
    );

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
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
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: colorScheme.outlineVariant,
          ),
      ],
    );
  }
}
