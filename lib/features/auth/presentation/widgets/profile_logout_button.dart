import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import '../../../../core/theme/app_icons.dart';

class ProfileLogoutButton extends StatefulWidget {
  const ProfileLogoutButton({super.key});

  @override
  State<ProfileLogoutButton> createState() => _ProfileLogoutButtonState();
}

class _ProfileLogoutButtonState extends State<ProfileLogoutButton> {
  // AuthLoading is shared with delete account, so track which button started
  // it: only this one shows a spinner while signing out.
  bool _isLoggingOut = false;

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authCubit = context.read<AuthCubit>();

    final confirmed = await showDialog<bool>(
      barrierColor: Colors.black.withValues(alpha: 0.5),
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logOut, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoggingOut = true);
    await authCubit.signOut();
    if (mounted) setState(() => _isLoggingOut = false);
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
          child: FilledButton.icon(
            onPressed: isBusy ? null : () => _confirmLogout(context),
            icon: _isLoggingOut
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.palette.danger,
                    ),
                  )
                : Icon(AppIcons.logOut, color: context.palette.danger),
            label: Text(
              l10n.logOut,
              style: TextStyle(
                color: context.palette.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Soft red: clearly destructive without shouting.
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.dangerContainer,
              foregroundColor: context.palette.danger,
              disabledBackgroundColor: context.palette.dangerContainer
                  .withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}
