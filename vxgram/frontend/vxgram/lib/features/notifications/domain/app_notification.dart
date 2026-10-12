import 'package:equatable/equatable.dart';

enum NotificationType {
  like, comment, follow, followRequest, followAccepted, other;

  static NotificationType parse(String? s) {
    switch (s) {
      case 'like': return like;
      case 'comment': return comment;
      case 'follow': return follow;
      case 'follow_request': return followRequest;
      case 'follow_accepted': return followAccepted;
      default: return other;
    }
  }
}

class AppNotification extends Equatable {
  const AppNotification({required this.id, required this.type, required this.actorId, required this.actorUsername, this.actorAvatar,
      this.postId, this.thumbUrl, this.body, required this.read, required this.createdAt});
  final String id, actorId, actorUsername; final NotificationType type;
  final String? actorAvatar, postId, thumbUrl, body; final bool read; final DateTime createdAt;
  @override
  List<Object?> get props => [id, read];
}
