import 'app_notification.dart';

abstract class NotificationRepository {
  /// Newest first. Pass the last item's createdAt as [before] to page.
  Future<List<AppNotification>> list({DateTime? before});
  Future<int> unreadCount();
  Future<void> markAllRead();
}
