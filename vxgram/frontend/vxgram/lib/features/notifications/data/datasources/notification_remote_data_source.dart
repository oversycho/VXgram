import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> list(DateTime? before);
  Future<int> unreadCount();
  Future<void> markAllRead();
}
