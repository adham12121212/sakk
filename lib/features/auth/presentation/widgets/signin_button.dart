import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'auth_primary_button.dart';

class SigninButton extends StatelessWidget {
  const SigninButton({super.key, required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthPrimaryButton(label: l10n.signIn, isLoading: isLoading, onPressed: onPressed);
  }
}