import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/auth/presentation/widgets/semented_toggle.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/locale_controller/locale_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';


class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({super.key});

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
              isLast: true,
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