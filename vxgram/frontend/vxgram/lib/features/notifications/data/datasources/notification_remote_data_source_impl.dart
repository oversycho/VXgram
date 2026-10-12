import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_remote_data_source.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;
  static const page = 30;

  @override
  Future<List<NotificationModel>> list(DateTime? before) async {
    final res = await _c.rpc('get_notifications', params: {'p_limit': page, 'p_before': before?.toUtc().toIso8601String()});
    return (res as List).map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<int> unreadCount() async => (await _c.rpc('unread_notification_count')) as int;

  @override
  Future<void> markAllRead() async { await _c.rpc('mark_notifications_read'); }
}
