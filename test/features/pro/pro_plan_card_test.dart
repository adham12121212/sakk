import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/di/get_it.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/pro/data/pro_status_data_source.dart';
import 'package:sakk/features/pro/domain/entities/pro_status.dart';
import 'package:sakk/features/pro/presentation/cubit/pro_cubit.dart';
import 'package:sakk/features/pro/presentation/widgets/pro_plan_card.dart';
import 'package:sakk/l10n/app_localizations.dart';

import 'pro_cubit_test.dart' show FakeStore, NoLog;

class _Server implements ProStatusDataSource {
  bool fail = true;

  @override
  Future<ProStatus> getStatus() async {
    if (fail) throw Exception('Could not find the function public.get_usage_status');
    return const ProStatus();
  }
}

void main() {
  tearDown(() => getIt.reset());

  testWidgets('a plan that can\'t load shows Retry, not an endless skeleton', (tester) async {
    final server = _Server();
    final users = StreamController<String?>();
    final pro = ProCubit(server, FakeStore(), userIdChanges: users.stream, logger: NoLog(), usageChanged: const Stream.empty());
    getIt.registerSingleton<ProCubit>(pro);
    users.add('user-1');

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ProPlanCard()),
    ));
    await tester.pumpAndSettle();
    expect(find.text(l10n.proStatusLoadFailed), findsOneWidget);

    server.fail = false;
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text(l10n.proStatusLoadFailed), findsNothing);
    expect(find.text(l10n.upgradeToPro), findsOneWidget);
  });
}
