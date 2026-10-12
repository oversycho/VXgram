import '../../domain/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({required super.id, required super.type, required super.actorId, required super.actorUsername, super.actorAvatar,
      super.postId, super.thumbUrl, super.body, required super.read, required super.createdAt});

  /// Row of the `get_notifications` RPC.
  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
      id: j['id'], type: NotificationType.parse(j['type'] as String?), actorId: j['actor_id'], actorUsername: j['actor_username'].toString(),
      actorAvatar: j['actor_avatar'], postId: j['post_id'], thumbUrl: j['thumb_url'], body: j['body'],
      read: j['is_read'] ?? false, createdAt: DateTime.parse(j['created_at']).toLocal());
}
