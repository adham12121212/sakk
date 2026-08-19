import '../../../../core/error/supabase_error_mapper.dart';
import '../../../../core/service/supabase_client.dart';
import '../models/notification_model.dart';

abstract class NotificationDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> deleteNotification(String notificationId);
  Future<void> createNotification(Map<String, dynamic> insertJson);
}

class NotificationDataSourceImpl implements NotificationDataSource {
  final SupabaseService supabaseService;
  static const String _table = 'notifications';

  NotificationDataSourceImpl({required this.supabaseService});

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final rows = await supabaseService.get(
        _table,
        filters: {'user_id': userId},
      );
      return rows.map((row) => NotificationModel.fromJson(row)).toList();
    } catch (e, st) {
      SupabaseErrorMapper.handle(e, st);
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabaseService.update(
        _table,
        {'is_read': true},
        matchColumn: 'id',
        matchValue: notificationId,
      );
    } catch (e, st) {
      SupabaseErrorMapper.handle(e, st);
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await supabaseService.delete(
        _table,
        matchColumn: 'id',
        matchValue: notificationId,
      );
    } catch (e, st) {
      SupabaseErrorMapper.handle(e, st);
    }
  }

  @override
  Future<void> createNotification(Map<String, dynamic> insertJson) async {
    try {
      await supabaseService.add(_table, insertJson);
    } catch (e, st) {
      SupabaseErrorMapper.handle(e, st);
    }
  }
}