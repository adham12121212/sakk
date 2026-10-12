import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/auth/domain/usecase/delete_account_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signin_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signin_with_google_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signout_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/signup_usecase.dart';
import 'package:sakk/features/auth/domain/usecase/update_avatar_usecase.dart';
import 'package:sakk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakk/features/auth/presentation/widgets/profile_account_section.dart';
import 'package:sakk/features/auth/presentation/widgets/profile_delete_account_button.dart';
import 'package:sakk/features/auth/presentation/widgets/profile_logout_button.dart';
import 'package:sakk/l10n/app_localizations.dart';

// The buttons only need an AuthCubit to exist; nothing is called.
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

Widget app({Locale locale = const Locale('en'), bool dark = false}) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => AuthCubit(_Signup(), _SignIn(), _SignOut(), _Avatar(), _Google(), _Delete()),
            child: const Padding(padding: EdgeInsets.all(20), child: ProfileAccountSection()),
          ),
        ),
      ),
    );

void main() {
  testWidgets('closed by default; opens to show log out and delete, and closes again', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('Account'), findsOneWidget);
    expect(find.byType(ProfileLogoutButton), findsNothing);
    expect(find.byType(ProfileDeleteAccountButton), findsNothing);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileLogoutButton), findsNothing);
    expect(find.byType(ProfileDeleteAccountButton), findsNothing);
  });

  testWidgets('screen readers hear whether it is open', (tester) async {
    bool? expanded() => tester
        .widget<Semantics>(find.ancestor(
          of: find.text('Account'),
          matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.expanded != null),
        ))
        .properties
        .expanded;

    await tester.pumpWidget(app());
    expect(expanded(), isFalse);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(expanded(), isTrue);
  });

  testWidgets('Arabic and dark mode, opened: no overflow', (tester) async {
    await tester.pumpWidget(app(locale: const Locale('ar'), dark: true));
    await tester.tap(find.text('الحساب'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileLogoutButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
