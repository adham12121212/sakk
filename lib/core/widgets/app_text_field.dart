import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  final String? Function(String?)? validator;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  final IconData? prefixIcon;
  final Widget? suffixIcon;

  final bool obscureText;
  final bool enabled;
  final bool readOnly;

  final int maxLines;

  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visible label; excluded from semantics because the field below
        // carries the same text as its own label.
        ExcludeSemantics(
          child: Text(label, style: textTheme.labelLarge?.copyWith(fontSize: 13.5)),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          textField: true,
          child: TextFormField(
            cursorColor: AppColors.primary,
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textInputAction: textInputAction,
            enabled: enabled,
            readOnly: readOnly,
            maxLines: obscureText ? 1 : maxLines,
            onFieldSubmitted: onFieldSubmitted,
            style: textTheme.bodyLarge?.copyWith(fontSize: 15),
            // Fill, radius and focus/error borders come from the app theme.
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              prefixIconColor: colorScheme.onSurfaceVariant,
              suffixIcon: suffixIcon,
              suffixIconColor: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
