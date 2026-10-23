import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/auth/domain/entities/user_entity.dart';
import 'package:sakk/features/auth/domain/usecase/get_user_usecase.dart';
import 'package:sakk/features/household/data/household_repo.dart';
import 'package:sakk/features/household/domain/household.dart';
import 'package:sakk/features/household/presentation/cubit/household_cubit.dart';
import 'package:sakk/features/household/presentation/widgets/household_card.dart';
import 'package:sakk/features/products/presentation/cubit/product_cubit.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _Repo implements HouseholdRepo {
  String? joinedWith;

  @override
  Future<Either<Failure, (Household?, List<HouseholdMember>)>> load() async =>
      const Right((null, <HouseholdMember>[]));

  @override
  Future<Either<Failure, void>> join({
    required String inviteCode,
    required String displayName,
  }) async {
    joinedWith = '$inviteCode/$displayName';
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Products implements ProductsCubit {
  @override
  Future<void> refresh() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _User implements GetUserUseCase {
  @override
  UserEntity? call() =>
      UserEntity(id: 'me', email: 'mona@example.com', name: 'Mona');
}

void main() {
  setUp(() async => getIt.reset());

  // Regression: the dialog's text controller was disposed while the closing
  // animation still drew the field ("used after being disposed").
  testWidgets('joining with a code closes the dialog cleanly', (tester) async {
    final repo = _Repo();
    getIt
      ..registerSingleton<GetUserUseCase>(_User())
      ..registerSingleton(HouseholdCubit(repo, _Products()));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: HouseholdCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a1b2c3d4e5');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.joinedWith, 'a1b2c3d4e5/Mona');
  });
}
