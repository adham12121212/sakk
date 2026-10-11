import 'package:flutter/material.dart';

import '../../features/products/domain/entities/product_entity.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_palette.dart';

/// Colours for a warranty status, from the theme palette (so they adapt to
/// dark mode): [foreground] for text/icons/rings, [background] for pills.
class WarrantyStatusColors {
  const WarrantyStatusColors(this.foreground, this.background);
  final Color foreground;
  final Color background;

  factory WarrantyStatusColors.of(BuildContext context, WarrantyStatus status) {
    final p = context.palette;
    return switch (status) {
      WarrantyStatus.active => WarrantyStatusColors(p.success, p.successContainer),
      WarrantyStatus.expiring => WarrantyStatusColors(p.warning, p.warningContainer),
      WarrantyStatus.expired => WarrantyStatusColors(p.danger, p.dangerContainer),
    };
  }
}

/// Pastel pill with a dot: "● Active" / "● Expiring" / "● Expired".
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = WarrantyStatusColors.of(context, status);
    final label = switch (status) {
      WarrantyStatus.active => l10n.active,
      WarrantyStatus.expiring => l10n.expiring,
      WarrantyStatus.expired => l10n.expired,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: colors.foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.foreground),
          ),
        ],
      ),
    );
  }
}
