import 'package:equatable/equatable.dart';

class InboxItem extends Equatable {
  const InboxItem({required this.id, required this.postId, required this.senderId, required this.senderUsername, this.senderAvatar,
      this.message, required this.seen, required this.createdAt, this.thumbUrl});
  final String id, postId, senderId, senderUsername; final String? senderAvatar, message, thumbUrl;
  final bool seen; final DateTime createdAt;
  InboxItem markSeen() => InboxItem(id: id, postId: postId, senderId: senderId, senderUsername: senderUsername, senderAvatar: senderAvatar,
      message: message, seen: true, createdAt: createdAt, thumbUrl: thumbUrl);
  @override
  List<Object?> get props => [id, seen];
}
