import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/theme/app_theme.dart';
import 'package:sakk/features/notification/data/models/notification_model.dart';
import 'package:sakk/features/notification/domain/entities/notification_entity.dart';
import 'package:sakk/features/notification/domain/entities/notification_message.dart';
import 'package:sakk/features/notification/presentation/widgets/notification_tile.dart';
import 'package:sakk/l10n/app_localizations.dart';

const renewal = NotificationMessage(NotificationKind.subscriptionRenewal, {
  'name': 'Netflix',
  'days': 3,
  'price': 240,
  'currency': 'EGP',
});

Map<String, dynamic> row({Object? message}) => {
  'id': '1',
  'user_id': 'u',
  'title': 'Subscription renewing soon',
  'subtitle': 'Netflix renews in 3 days for 240 EGP',
  'type': 'warning',
  'created_at': DateTime.now().toIso8601String(),
  'message': message,
};

Widget tile(NotificationEntity n, Locale locale) => MaterialApp(
  locale: locale,
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: NotificationTile(notification: n)),
);

void main() {
  test('a message survives the round trip through the database row', () {
    final model = NotificationModel.fromJson(row(message: renewal.toJson()));
    expect(model.message?.kind, NotificationKind.subscriptionRenewal);
    expect(model.message?.args['name'], 'Netflix');
    expect(
      NotificationModel.fromJson(row()).message,
      isNull,
      reason: 'older rows have none',
    );
    expect(
      NotificationModel.fromJson(
        row(message: {'kind': 'somethingNew', 'args': {}}),
      ).message,
      isNull,
      reason: 'a kind this version does not know falls back to the text',
    );
  });

  testWidgets('a notification made in English shows in Arabic', (tester) async {
    final n = NotificationModel.fromJson(row(message: renewal.toJson()));
    await tester.pumpWidget(tile(n, const Locale('ar')));

    expect(find.text('Netflix renews in 3 days for 240 EGP'), findsNothing);
    expect(find.textContaining('٣'), findsOneWidget);
    expect(find.textContaining('٢٤٠'), findsOneWidget);
  });

  testWidgets('an older row shows its stored text', (tester) async {
    final n = NotificationModel.fromJson(row());
    await tester.pumpWidget(tile(n, const Locale('ar')));

    expect(find.text('Netflix renews in 3 days for 240 EGP'), findsOneWidget);
  });
}
