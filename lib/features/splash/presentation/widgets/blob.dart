


import 'package:flutter/cupertino.dart';

import '../../../../core/constant/app_colors.dart';

class Blob extends StatelessWidget {
  final double size;
  const Blob({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.06),
      ),
    );
  }
}