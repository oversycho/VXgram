import '../../domain/comment.dart';

class CommentModel extends Comment {
  const CommentModel({required super.id, required super.userId, required super.username, super.avatarUrl, required super.body, required super.createdAt});

  /// Row of the `get_comments` RPC.
  factory CommentModel.fromRpc(Map<String, dynamic> j) => CommentModel(
      id: j['id'], userId: j['user_id'], username: j['username'].toString(), avatarUrl: j['avatar_url'],
      body: j['body'], createdAt: DateTime.parse(j['created_at']).toLocal());

  /// Row returned by insert(...).select('..., profiles(username, avatar_url)').
  factory CommentModel.fromInsert(Map<String, dynamic> j) {
    final p = Map<String, dynamic>.from(j['profiles'] as Map);
    return CommentModel(
        id: j['id'], userId: j['user_id'], username: p['username'].toString(), avatarUrl: p['avatar_url'],
        body: j['body'], createdAt: DateTime.parse(j['created_at']).toLocal());
  }
}
