import 'package:flutter/material.dart';

/// Full-width scan source action: filled (primary) or outlined (secondary),
/// both from the app theme.
class ScanSourceButton extends StatelessWidget {
  const ScanSourceButton.filled({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : isFilled = true;

  const ScanSourceButton.outlined({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : isFilled = false;

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: isFilled
          ? FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
    );
  }
}
