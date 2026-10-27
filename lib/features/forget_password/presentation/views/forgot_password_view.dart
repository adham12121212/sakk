import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/util/validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
import '../../../auth/presentation/widgets/email_text_field.dart';
import '../cubit/password_reset_cubit.dart';
import 'otp_verification_view.dart';
import '../../../../core/theme/app_icons.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PasswordResetCubit>(),
      child: const _ForgotPasswordBody(),
    );
  }
}

class _ForgotPasswordBody extends StatefulWidget {
  const _ForgotPasswordBody();

  @override
  State<_ForgotPasswordBody> createState() => _ForgotPasswordBodyState();
}

class _ForgotPasswordBodyState extends State<_ForgotPasswordBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PasswordResetCubit>().sendOtp(
      AppValidators.normalizeEmail(_emailController.text),
    );
  }

  void _handleStateChange(BuildContext context, PasswordResetState state) {
    // Screens further down the stack share this cubit; only the visible one
    // should react (otherwise "resend code" pushes a second code screen).
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (state is PasswordResetError) {
      AppSnackBar.error(
        context,
        userFacingError(AppLocalizations.of(context)!, state.message),
      );
    } else if (state is PasswordResetOtpSent) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PasswordResetCubit>(),
            child: OtpVerificationView(
              email: AppValidators.normalizeEmail(_emailController.text),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: BlocConsumer<PasswordResetCubit, PasswordResetState>(
          listener: _handleStateChange,
          builder: (context, state) {
            final isLoading = state is PasswordResetLoading;
            return SafeArea(
              child: SingleChildScrollView(
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
                        CircleIconButton(
                          icon: AppIcons.back,
                          semanticLabel: l10n.back,
                          onTap: () => Navigator.of(context).pop(),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(height: 28.h),
                        Text(
                          l10n.forgotPassword,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.enteryouremailandwellsendyouacodetoresetyourpassword,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        SizedBox(height: 32.h),
                        EmailTextField(
                          controller: _emailController,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        SizedBox(height: 28.h),
                        AuthPrimaryButton(
                          label: l10n.sendCode,
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          l10n.resetGoogleAccountNote,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
