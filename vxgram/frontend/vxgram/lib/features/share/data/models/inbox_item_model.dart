import '../../domain/inbox_item.dart';

class InboxItemModel extends InboxItem {
  const InboxItemModel({required super.id, required super.postId, required super.senderId, required super.senderUsername, super.senderAvatar,
      super.message, required super.seen, required super.createdAt, super.thumbUrl});
  /// Row of the `get_inbox` RPC.
  factory InboxItemModel.fromJson(Map<String, dynamic> j) => InboxItemModel(
      id: j['id'], postId: j['post_id'], senderId: j['sender_id'], senderUsername: j['sender_username'].toString(), senderAvatar: j['sender_avatar'],
      message: j['message'], seen: j['seen'] ?? false, createdAt: DateTime.parse(j['created_at']).toLocal(), thumbUrl: j['thumb_url']);
}
