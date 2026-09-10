import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';


class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
       children: [
         Text(
           text,
           style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color:
           colorScheme.onSurface),
         ),
       ],
    );
  }
}