import 'package:flutter/material.dart';

import '../../../../core/constant/app_colors.dart';

/// Full-width scan source action: filled (primary) or outlined (secondary),
/// both from the app theme.
class ScanSourceButton extends StatelessWidget {
  const ScanSourceButton.filled({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : isFilled = true,
       badge = null;

  const ScanSourceButton.outlined({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
  }) : isFilled = false;

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isFilled;

  /// A short tag after the label, e.g. "Pro".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: isFilled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: badge == null
                  ? Text(label)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label),
                        const SizedBox(width: 8),
                        _Badge(badge!),
                      ],
                    ),
              style: OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.brandGradientColors),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
