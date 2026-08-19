import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sakk/core/widgets/app_snackbar.dart';
import 'package:sakk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakk/features/auth/presentation/widgets/signup_view_body.dart';

import '../../../../core/route/app_router.dart';

class SignupViewConsumerBody extends StatelessWidget {
  const SignupViewConsumerBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthSuccess():
            AppSnackBar.success(
              context,
              'Welcome to Sakk!',
            );

            context.go(AppRoutes.home);
            break;
          case AuthError():
            AppSnackBar.error(
              context,
              state.message,
            );

            break;
          default:
            break;
        }
      },
      builder: (context, state) {
        return SignupViewBody(isLoading: state is AuthLoading,);
      },
    );
  }
}