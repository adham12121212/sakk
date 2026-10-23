import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/auth/presentation/widgets/language_switch.dart';
import 'package:sakk/features/auth/presentation/widgets/signin_form.dart';
import 'package:sakk/features/auth/presentation/widgets/signin_header.dart';

class SigninViewBody extends StatelessWidget {
  const SigninViewBody({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SigninHeader(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 28.h,
                        ),
                        child: SigninForm(isLoading: isLoading),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Pinned to the top corner (right in English, left in Arabic) so
          // it doesn't push the logo down or scroll away with the form.
          PositionedDirectional(
            top: 8.h,
            end: 16.w,
            child: const LanguageSwitch(),
          ),
        ],
      ),
    );
  }
}
