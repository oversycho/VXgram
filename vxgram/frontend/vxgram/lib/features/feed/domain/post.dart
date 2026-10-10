import 'package:equatable/equatable.dart';

/// Pure entities: no JSON, no backend types.
class MediaItem extends Equatable {
  const MediaItem({required this.id, required this.url, required this.isVideo, required this.position, this.width, this.height, this.thumbUrl});
  final String id, url; final bool isVideo; final int position; final int? width, height;
  final String? thumbUrl; // small preview used by grids
  @override
  List<Object?> get props => [id, url];
}

class Post extends Equatable {
  const Post({required this.id, required this.userId, required this.username, this.avatarUrl, required this.caption,
      required this.createdAt, required this.likesCount, required this.commentsCount, required this.likedByMe, required this.media});
  final String id, userId, username, caption; final String? avatarUrl;
  final DateTime createdAt; final int likesCount, commentsCount; final bool likedByMe; final List<MediaItem> media;

  Post copyWith({int? likesCount, int? commentsCount, bool? likedByMe}) => Post(
      id: id, userId: userId, username: username, avatarUrl: avatarUrl, caption: caption, createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount, commentsCount: commentsCount ?? this.commentsCount, likedByMe: likedByMe ?? this.likedByMe, media: media);

  @override
  List<Object?> get props => [id, likesCount, commentsCount, likedByMe];
}
