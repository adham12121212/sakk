


import 'package:flutter/cupertino.dart';

import '../../../../core/constant/app_colors.dart';

class Blob extends StatelessWidget {
  final double size;
  const Blob({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withOpacity(0.06),
      ),
    );
  }
}