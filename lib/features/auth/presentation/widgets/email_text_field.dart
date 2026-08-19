// email_text_field.dart
import 'package:flutter/material.dart';
import '../../../../core/util/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    super.key,
    required this.controller,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTextField(
      controller: controller,
      label: l10n.emailAddress,
      hint: l10n.emailHint,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.alternate_email,
      validator: (value) => AppValidators.email(context, value),
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
    );
  }
}