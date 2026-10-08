import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import 'delete_account_dialog.dart';

/// Styled like [ProfileLogoutButton]: full-width outlined error button.
class ProfileDeleteAccountButton extends StatefulWidget {
  const ProfileDeleteAccountButton({super.key});

  @override
  State<ProfileDeleteAccountButton> createState() => _ProfileDeleteAccountButtonState();
}

class _ProfileDeleteAccountButtonState extends State<ProfileDeleteAccountButton> {
  // AuthLoading is shared with log out, so track which button started it:
  // only this one shows a spinner while the account is being deleted.
  bool _isDeleting = false;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authCubit = context.read<AuthCubit>();
    // Captured up front: ProfileView navigates to sign-in as soon as the
    // cubit returns to AuthInitial, so this context won't be around after.
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDeleteAccountDialog(context);
    if (!confirmed) return;

    setState(() => _isDeleting = true);
    await authCubit.deleteAccount();
    if (mounted) setState(() => _isDeleting = false);
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
        return SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : () => _confirmDelete(context),
            icon: _isDeleting
                ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.error,
              ),
            )
                : Icon(Icons.delete_forever_outlined, color: AppColors.error),
            label: Text(l10n.deleteAccount, style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        );
      },
    );
  }
}
