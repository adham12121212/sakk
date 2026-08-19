
import 'package:flutter/material.dart';

import '../../../../core/constant/app_colors.dart';

class AuthFooter extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthFooter({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(question),
          TextButton(
            onPressed: onTap,
            child: Text(actionLabel, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}