import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

enum SnackBarType {
  success,
  error,
}

class AppSnackBar {
  AppSnackBar._();

  static void show(
      BuildContext context, {
        required String message,
        required SnackBarType type,
      }) {
    final theme = Theme.of(context);

    final bool isSuccess = type == SnackBarType.success;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 0,
          backgroundColor: Colors.transparent,
          duration: const Duration(seconds: 3),
          content: _SnackBarContent(
            message: message,
            isSuccess: isSuccess,
            color: isSuccess
                ? AppColors.success
                : AppColors.error,
            icon: isSuccess
                ? Icons.check_circle_rounded
                : Icons.error,
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  static void success(
      BuildContext context,
      String message,
      ) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
    );
  }

  static void error(
      BuildContext context,
      String message,
      ) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
    );
  }
}

class _SnackBarContent extends StatelessWidget {
  const _SnackBarContent({
    required this.message,
    required this.icon,
    required this.color,
    required this.textStyle,
    required this.isSuccess,
  });

  final String message;
  final IconData icon;
  final Color color;
  final TextStyle? textStyle;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}