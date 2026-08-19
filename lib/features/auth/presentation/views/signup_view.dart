import 'package:flutter/material.dart';
import 'package:sakk/features/auth/presentation/widgets/signup_view_consumer_body.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  static const String routeName = '/signup';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: SignupViewConsumerBody(),
      ),
    );
  }
}