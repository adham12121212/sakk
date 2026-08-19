// password_text_field.dart
import 'package:flutter/material.dart';
import '../../../../core/util/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.label,
    this.hint,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  /// Optional overrides — when omitted, this behaves exactly as the
  /// original "password" field (label/hint/validator from l10n).
  /// Pass these to reuse this widget for a confirm-password field.
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTextField(
      controller: controller,
      label: label ?? l10n.password,
      hint: hint ?? l10n.passwordHint,
      obscureText: obscureText,
      validator: validator ?? (value) => AppValidators.password(context, value),
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      suffixIcon: IconButton(
        tooltip: obscureText ? 'Show password' : 'Hide password',
        onPressed: onToggleVisibility,
        icon: Icon(
          obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    );
  }
}