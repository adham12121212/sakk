import 'package:flutter/material.dart';

import '../../../../core/constant/app_colors.dart';

/// A full-width, 52px action button for picking an image source (camera or
/// gallery) on the scan screen. Use [ScanSourceButton.filled] for the
/// primary action and [ScanSourceButton.outlined] for the secondary one.
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
    final shape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isFilled
          ? FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label:
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: shape,
        ),
      )
          : OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label:
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
          shape: shape,
        ),
      ),
    );
  }
}