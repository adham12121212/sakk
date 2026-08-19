import 'package:flutter/material.dart';
import 'package:sakk/features/auth/presentation/widgets/signin_view_consumer_body.dart';

class SigninView extends StatelessWidget {
  const SigninView({super.key});

  static const String routeName = '/signin';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: const Scaffold(
        backgroundColor: Colors.white,
        body: SigninViewConsumerBody(),
      ),
    );
  }
}