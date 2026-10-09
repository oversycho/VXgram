import '../../domain/post.dart';

/// Maps one row of the `get_posts` RPC to the domain entity.
class PostModel extends Post {
  const PostModel({required super.id, required super.userId, required super.username, super.avatarUrl, required super.caption,
      required super.createdAt, required super.likesCount, required super.commentsCount, required super.likedByMe, required super.media});

  factory PostModel.fromJson(Map<String, dynamic> j) => PostModel(
        id: j['id'], userId: j['user_id'], username: j['username'].toString(), avatarUrl: j['avatar_url'], caption: j['caption'] ?? '',
        createdAt: DateTime.parse(j['created_at']).toLocal(), likesCount: j['likes_count'] ?? 0, commentsCount: j['comments_count'] ?? 0,
        likedByMe: j['liked_by_me'] ?? false,
        media: (j['media'] as List).map((m) => _media(Map<String, dynamic>.from(m))).toList(),
      );

  static MediaItem _media(Map<String, dynamic> m) => MediaItem(
      id: m['id'], url: m['url'], isVideo: m['type'] == 'video', position: m['position'] ?? 0, width: m['width'], height: m['height']);
}
