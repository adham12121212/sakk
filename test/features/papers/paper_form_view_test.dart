import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/papers/domain/entities/paper.dart';
import 'package:sakk/features/papers/domain/usecase/delete_paper_usecase.dart';
import 'package:sakk/features/papers/domain/usecase/get_papers_usecase.dart';
import 'package:sakk/features/papers/domain/usecase/save_paper_usecase.dart';
import 'package:sakk/features/papers/presentation/cubit/paper_form_cubit.dart';
import 'package:sakk/features/papers/presentation/cubit/papers_cubit.dart';
import 'package:sakk/features/papers/presentation/views/paper_form_view.dart';
import 'package:sakk/l10n/app_localizations.dart';

class _NoGet implements GetPapersUseCase {
  @override
  Future<Either<Failure, List<Paper>>> call() async => const Right([]);
}

/// Captures what the form sends.
class CaptureSave implements SavePaperUseCase {
  PaperDraft? sent;
  @override
  Future<Either<Failure, Paper>> call(PaperDraft draft) async {
    sent = draft;
    return Right(Paper(id: 'new', kind: draft.kind, title: draft.title));
  }
}

class _NoDelete implements DeletePaperUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Widget app(
  CaptureSave save, {
  Paper? existing,
  Locale locale = const Locale('en'),
}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(
    locale: locale,
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    // A first page so the form has something to pop back to.
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      PaperFormCubit(save, _NoDelete(), PapersCubit(_NoGet())),
                  child: PaperFormView(existing: existing),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder saveButton(String label) => find.widgetWithText(FilledButton, label);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new paper needs an expiry date or "Doesn\'t expire"', (
    tester,
  ) async {
    final save = CaptureSave();
    await tester.pumpWidget(app(save));
    await open(tester);

    await tester.ensureVisible(saveButton('Add paper'));
    expect(
      tester.widget<FilledButton>(saveButton('Add paper')).onPressed,
      isNull,
    );

    await tapVisible(tester, find.text("Doesn't expire"));
    await tester.enterText(
      find.byType(TextFormField).at(1),
      ' 29901011234567 ',
    );
    await tapVisible(tester, saveButton('Add paper'));

    expect(save.sent?.kind, PaperKind.nationalId);
    expect(save.sent?.number, '29901011234567');
    expect(save.sent?.expiryDate, isNull);
    expect(save.sent?.title, isNull);
    expect(find.text('open'), findsOneWidget); // popped back
  });

  testWidgets('"Other" needs a name', (tester) async {
    final save = CaptureSave();
    await tester.pumpWidget(app(save));
    await open(tester);

    await tapVisible(tester, find.text('Other'));
    await tapVisible(tester, find.text("Doesn't expire"));
    await tapVisible(tester, saveButton('Add paper'));
    expect(find.text('Enter a name for this paper'), findsOneWidget);
    expect(save.sent, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'Club card');
    await tapVisible(tester, saveButton('Add paper'));
    expect(save.sent?.kind, PaperKind.other);
    expect(save.sent?.title, 'Club card');
  });

  testWidgets('editing keeps the saved photos and the expiry date', (
    tester,
  ) async {
    final save = CaptureSave();
    final existing = Paper(
      id: 'p',
      kind: PaperKind.passport,
      expiryDate: DateTime(2030, 5, 1),
      frontPath: 'u/front.jpg',
      // Its link couldn't be signed: still kept.
      backPath: 'u/back.jpg',
    );
    await tester.pumpWidget(app(save, existing: existing));
    await open(tester);

    expect(find.text('Edit paper'), findsOneWidget);
    expect(find.text('May 1, 2030'), findsOneWidget);
    await tapVisible(tester, saveButton('Save Changes'));

    expect(save.sent?.previous, existing);
    expect(save.sent?.expiryDate, DateTime(2030, 5, 1));
    expect(save.sent?.frontPath, 'u/front.jpg');
    expect(save.sent?.backPath, 'u/back.jpg');
    expect(save.sent?.newFrontImage, isNull);
  });

  testWidgets('lays out in Arabic without overflow', (tester) async {
    await tester.pumpWidget(app(CaptureSave(), locale: const Locale('ar')));
    await open(tester);
    expect(find.text('ضيف ورقة'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
