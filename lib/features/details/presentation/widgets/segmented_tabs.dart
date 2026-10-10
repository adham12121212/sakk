import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';

/// iOS-style segmented control: grey track, white sliding selection.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.detailsTab, l10n.invoiceTab];
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFE9EDF3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? colorScheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected ? context.palette.cardShadow : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
