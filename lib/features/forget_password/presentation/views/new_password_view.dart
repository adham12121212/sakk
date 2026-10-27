import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/user_facing_error.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
import '../../../auth/presentation/widgets/password_text_field.dart';
import '../cubit/password_reset_cubit.dart';

class NewPasswordView extends StatefulWidget {
  const NewPasswordView({super.key});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PasswordResetCubit>().updatePassword(_passwordController.text);
  }

  void _handleStateChange(BuildContext context, PasswordResetState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state is PasswordResetError) {
      AppSnackBar.error(context, userFacingError(l10n, state.message));
    } else if (state is PasswordResetCompleted) {
      AppSnackBar.success(context, l10n.passwordupdatedpleasesigninagain);
      context.go(AppRoutes.signin);
    }
  }

  Future<void> _abandon() async {
    await context.read<PasswordResetCubit>().abandon();
    if (!mounted) return;
    context.go(AppRoutes.signin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // The verified code already signed the user in, so going back has to
    // sign them out rather than return to the code screen.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.read<PasswordResetCubit>().state is PasswordResetLoading) {
          return;
        }
        _abandon();
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          body: BlocConsumer<PasswordResetCubit, PasswordResetState>(
            listener: _handleStateChange,
            builder: (context, state) {
              final isLoading = state is PasswordResetLoading;
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        Text(
                          l10n.setNewPassword,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.chooseNewPasswordSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(height: 32.h),
                        PasswordTextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          enabled: !isLoading,
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: 6.h),
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 4.w),
                          child: Text(
                            l10n.atleast8characters,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        PasswordTextField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          onToggleVisibility: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          label: l10n.confirmPassword,
                          hint: l10n.confirmPasswordHint,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return l10n.confirmPasswordRequired;
                            }
                            if (v != _passwordController.text) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 28.h),
                        AuthPrimaryButton(
                          label: l10n.updatePasswordButton,
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
