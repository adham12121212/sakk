import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_primary_button.dart';
import '../../../auth/presentation/widgets/email_text_field.dart';
import '../cubit/password_reset_cubit.dart';
import 'otp_verification_view.dart';

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
    context.read<PasswordResetCubit>().sendOtp(_emailController.text.trim());
  }

  void _handleStateChange(BuildContext context, PasswordResetState state) {
    if (state is PasswordResetError) {
      AppSnackBar.error(context, state.message);
    } else if (state is PasswordResetOtpSent) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PasswordResetCubit>(),
            child: OtpVerificationView(email: _emailController.text.trim()),
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      Text(
                        l10n.forgotPassword,
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.enteryouremailandwellsendyouacodetoresetyourpassword,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.4),
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
                    ],
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