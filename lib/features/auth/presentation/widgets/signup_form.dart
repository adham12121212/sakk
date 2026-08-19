import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakk/features/auth/presentation/widgets/social_login_buttons.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../core/util/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import 'auth_footer.dart';
import 'auth_primary_button.dart';
import 'email_text_field.dart';
import 'password_text_field.dart';

class SignupForm extends StatefulWidget {
  final bool isLoading;
  const SignupForm({super.key, required this.isLoading});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreateAccountPressed() {
    final isFormValid = _formKey.currentState!.validate();

    setState(() => _showTermsError = !_agreedToTerms);

    if (!isFormValid || !_agreedToTerms) return;

    context.read<AuthCubit>().signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _nameController,
            label: l10n.fullName,
            hint: l10n.fullNameHint,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            validator: (v) =>
                AppValidators.requiredField(context, v, fieldName: l10n.fullNameRequired),
          ),
          AppSpacing.h20,

          EmailTextField(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
          ),
          AppSpacing.h20,

          AppTextField(
            controller: _phoneController,
            label: l10n.phoneNumber,
            hint: l10n.phoneHint,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            validator: (v) => AppValidators.phone(context, v),
          ),
          AppSpacing.h20,

          PasswordTextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: AppSizes.s4),
            child: Text(
              'At least 8 characters',
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
            ),
          ),
          AppSpacing.h20,

          PasswordTextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            label: l10n.confirmPassword,
            hint: l10n.confirmPasswordHint,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            onFieldSubmitted: (_) => _onCreateAccountPressed(),
            validator: (v) => AppValidators.confirmPassword(
              context,
              value: v,
              passwordController: _passwordController,
            ),
          ),
          SizedBox(height: 16.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                activeColor: AppColors.primary,
                onChanged: widget.isLoading
                    ? null
                    : (v) => setState(() {
                  _agreedToTerms = v ?? false;
                  if (_agreedToTerms) _showTermsError = false;
                }),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: AppColors.black.withOpacity(0.7), fontSize: 13.sp),
                      children: [
                        TextSpan(text: l10n.agreeToTermsPrefix),
                        TextSpan(
                          text: l10n.termsOfService,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push('/terms'),
                        ),
                        TextSpan(text: l10n.and),
                        TextSpan(
                          text: l10n.privacyPolicy,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.push('/privacy'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_showTermsError) ...[
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.only(left: AppSizes.s12),
              child: Text(
                l10n.pleaseAgreeToTerms,
                style: TextStyle(fontSize: 12.sp, color: AppColors.error),
              ),
            ),
          ],

          SizedBox(height: 20.h),

          AuthPrimaryButton(
            label: l10n.createAccount,
            isLoading: widget.isLoading,
            onPressed: _onCreateAccountPressed,
          ),
          AppSpacing.h24,

          const SocialLoginButtons(showBiometric: false),
          AppSpacing.h24,

          AuthFooter(
            question: l10n.alreadyHaveAccount,
            actionLabel: l10n.signIn,
            onTap: widget.isLoading ? () {} : () => context.pop(),
          ),
        ],
      ),
    );
  }
}