import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/locale_controller/locale_controller.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/auth/domain/usecase/delete_account_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signin_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signin_with_google_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signout_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signup_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/update_avatar_usecase.dart';
import 'package:sakk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakk/features/auth/presentation/widgets/language_switch.dart';
import 'package:sakk/features/auth/presentation/widgets/signin_view_body.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The sign-in screen only needs an AuthCubit to exist; nothing is called.
class _Signup implements SignupUsecase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _SignIn implements SignInUseCase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _SignOut implements SignOutUseCase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Avatar implements UpdateAvatarUseCase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Google implements SignInWithGoogleUseCase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Delete implements DeleteAccountUseCase {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

Widget app(Locale locale) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => AuthCubit(_Signup(), _SignIn(), _SignOut(), _Avatar(), _Google(), _Delete()),
            child: const SigninViewBody(isLoading: false),
          ),
        ),
      ),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    getIt.registerSingleton(LocaleController());
  });

  for (final (locale, rtl) in [(const Locale('en'), false), (const Locale('ar'), true)]) {
    testWidgets('${locale.languageCode}: the switch sits in the top ${rtl ? 'left' : 'right'} corner', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(locale));
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byType(LanguageSwitch));
      expect(box.top, lessThan(40));
      if (rtl) {
        expect(box.left, lessThan(40));
      } else {
        expect(box.right, greaterThan(390 - 40));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('it stays put when the form scrolls', (tester) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();

    final before = tester.getRect(find.byType(LanguageSwitch));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(LanguageSwitch)), before);
  });
}
