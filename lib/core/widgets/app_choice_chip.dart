import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

/// A choice pill: brand colour with white text when selected, an outline
/// with grey text when not. Colours are set here, not left to the theme,
/// so every choice chip in the app reads the same.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: colorScheme.surface,
      side: BorderSide(
        color: selected ? AppColors.primary : colorScheme.outlineVariant,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? Colors.white : colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
