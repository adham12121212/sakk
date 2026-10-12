import 'package:flutter/material.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/locale_controller/locale_controller.dart';
import 'segmented_toggle.dart';

/// EN/AR toggle for screens shown before sign-in (onboarding, sign in).
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = getIt<LocaleController>();
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) => SegmentedToggle<String>(
        options: const {'en': 'EN', 'ar': 'AR'},
        selected: locale.languageCode,
        onChanged: (code) => localeController.setLocale(Locale(code)),
      ),
    );
  }
}
