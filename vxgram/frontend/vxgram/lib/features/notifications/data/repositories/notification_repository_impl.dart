import '../../../../core/failure.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._ds);
  final NotificationRemoteDataSource _ds;
  @override
  Future<List<AppNotification>> list({DateTime? before}) => guard(() => _ds.list(before));
  @override
  Future<int> unreadCount() => guard(_ds.unreadCount);
  @override
  Future<void> markAllRead() => guard(_ds.markAllRead);
}
