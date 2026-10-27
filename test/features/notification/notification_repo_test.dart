import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/notification/data/notification_data_source/notification_data_source.dart';
import 'package:sakk/features/notification/data/notification_repo_impl/notification_repo_impl.dart';
import 'package:sakk/features/notification/domain/entities/notification_entity.dart';
import 'package:sakk/features/notification/domain/entities/notification_message.dart';

/// Rows saved for the account, as the database would hold them.
class _Rows implements NotificationDataSource {
  final saved = <Map<String, dynamic>>[];

  @override
  Future<bool> hasNotificationWithKey(String userId, String key) async =>
      saved.any(
        (r) => r['user_id'] == userId && (r['message'] as Map?)?['key'] == key,
      );

  @override
  Future<void> createNotification(Map<String, dynamic> insertJson) async =>
      saved.add(insertJson);

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Online implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _NoLog implements AppLogger {
  @override
  dynamic noSuchMethod(Invocation i) {}
}

const reminder = NotificationMessage(NotificationKind.subscriptionRenewal, {
  'name': 'Netflix',
  'days': 3,
  'price': 240,
  'currency': 'EGP',
});

void main() {
  late _Rows rows;
  late NotificationRepoImpl repo;
  setUp(() {
    rows = _Rows();
    repo = NotificationRepoImpl(rows, _Online(), _NoLog());
  });

  Future<void> add(String userId, NotificationMessage? message) =>
      repo.addNotification(
        userId: userId,
        title: 'Subscription renewing soon',
        subtitle: 'Netflix renews in 3 days for 240 EGP',
        type: NotificationType.warning,
        message: message,
      );

  test('a reminder another device already added is not added again', () async {
    await add('u', reminder.keyed('subscription:n:3d-2026-10-29'));
    await add('u', reminder.keyed('subscription:n:3d-2026-10-29'));
    expect(rows.saved, hasLength(1));
  });

  test('different reminders and different accounts are kept', () async {
    await add('u', reminder.keyed('subscription:n:3d-2026-10-29'));
    await add('u', reminder.keyed('subscription:n:3d-2026-11-29'));
    await add('other', reminder.keyed('subscription:n:3d-2026-10-29'));
    expect(rows.saved, hasLength(3));
  });

  test('notifications without a key are always added', () async {
    await add('u', reminder);
    await add('u', null);
    expect(rows.saved, hasLength(2));
  });
}
