import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import 'delete_account_dialog.dart';

class ProfileDeleteAccountButton extends StatelessWidget {
  const ProfileDeleteAccountButton({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authCubit = context.read<AuthCubit>();
    // Captured up front: ProfileView navigates to sign-in as soon as the
    // cubit returns to AuthInitial, so this context won't be around after.
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDeleteAccountDialog(context);
    if (!confirmed) return;

    await authCubit.deleteAccount();
    if (authCubit.state is AuthInitial) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isBusy = state is AuthLoading;
        return TextButton.icon(
          onPressed: isBusy ? null : () => _confirmDelete(context),
          icon: Icon(Icons.delete_forever_outlined, color: AppColors.error),
          label: Text(l10n.deleteAccount, style: TextStyle(color: AppColors.error)),
        );
      },
    );
  }
}