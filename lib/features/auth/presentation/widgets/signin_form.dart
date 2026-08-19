import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import 'auth_footer.dart';
import 'email_text_field.dart';
import 'forgot_password_button.dart';
import 'password_text_field.dart';
import 'signin_button.dart';
import 'social_login_buttons.dart';

class SigninForm extends StatefulWidget {
  const SigninForm({
    super.key,
    required this.isLoading,
  });

  final bool isLoading;

  @override
  State<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().signin(
      email: _emailController.text.trim(),
      password: _passwordController.text,

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
          Text(
            l10n.welcomeBack,
            style: TextStyle(
              fontSize: 23.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            l10n.signIn,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 28.h),
          EmailTextField(
            controller: _emailController,
          ),

          SizedBox(height: 20.h),

          PasswordTextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),

          const ForgotPasswordButton(),

          SizedBox(height: 15.h),

          SigninButton(
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),

          SizedBox(height: 28.h),

          const SocialLoginButtons(),

          SizedBox(height: 30.h),
          AuthFooter(
            question: l10n.noAccount,
            actionLabel: l10n.signUp,
            onTap: () => context.push('/signup'),
          ),

        ],
      ),
    );
  }
}