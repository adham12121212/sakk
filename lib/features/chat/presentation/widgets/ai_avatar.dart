import 'package:flutter/material.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/constant/app_colors.dart';

/// Brand-gradient circle with the assistant's sparkle icon.
class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradientColors,
        ),
      ),
      child: Icon(AppIcons.aiFilled, size: size * 0.5, color: Colors.white),
    );
  }
}
