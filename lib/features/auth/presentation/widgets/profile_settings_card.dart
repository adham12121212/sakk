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

/// Language + theme toggles. Reads ThemeController/LocaleController
/// directly (they're app-wide singletons, same instance main.dart reads)
/// — NOT via AuthCubit, which is screen-scoped and can't drive live
/// app-wide changes. See main.dart for how these two connect.
class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeController = getIt<LocaleController>();
    final themeController = getIt<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListenableBuilder(
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
              Divider(height: 1, color: Colors.grey.shade100),
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
      ),
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
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
          ),
          child,
        ],
      ),
    );
  }
}