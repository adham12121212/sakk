import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/paper.dart';

/// Icon, colour and name for each kind of paper.
class PaperUi {
  PaperUi._();

  static IconData icon(PaperKind kind) => switch (kind) {
    PaperKind.nationalId => AppIcons.nationalId,
    PaperKind.passport => AppIcons.passport,
    PaperKind.drivingLicence => AppIcons.drivingLicence,
    PaperKind.carLicence => AppIcons.vehicles,
    PaperKind.carInsurance => AppIcons.shield,
    PaperKind.healthInsurance => AppIcons.healthInsurance,
    PaperKind.rentalContract => AppIcons.rentalContract,
    PaperKind.other => AppIcons.paper,
  };

  static Color color(PaperKind kind) => switch (kind) {
    PaperKind.nationalId => const Color(0xFF3B82F6),
    PaperKind.passport => const Color(0xFF6366F1),
    PaperKind.drivingLicence => const Color(0xFF0EA5E9),
    PaperKind.carLicence => const Color(0xFFF97316),
    PaperKind.carInsurance => const Color(0xFFF59E0B),
    PaperKind.healthInsurance => const Color(0xFFEF4444),
    PaperKind.rentalContract => const Color(0xFF22C55E),
    PaperKind.other => const Color(0xFF9CA3AF),
  };

  static String kindName(AppLocalizations l10n, PaperKind kind) =>
      switch (kind) {
        PaperKind.nationalId => l10n.paperNationalId,
        PaperKind.passport => l10n.paperPassport,
        PaperKind.drivingLicence => l10n.paperDrivingLicence,
        PaperKind.carLicence => l10n.paperCarLicence,
        PaperKind.carInsurance => l10n.paperCarInsurance,
        PaperKind.healthInsurance => l10n.paperHealthInsurance,
        PaperKind.rentalContract => l10n.paperRentalContract,
        PaperKind.other => l10n.paperOther,
      };

  /// The paper's own title, or its kind's name.
  static String name(AppLocalizations l10n, Paper paper) {
    final title = paper.title;
    return title != null && title.isNotEmpty
        ? title
        : kindName(l10n, paper.kind);
  }
}
