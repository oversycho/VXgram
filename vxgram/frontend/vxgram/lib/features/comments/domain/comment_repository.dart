import 'comment.dart';

abstract class CommentRepository {
  String? get currentUserId;
  /// Newest first. Pass the last item's createdAt as [before] to page.
  Future<List<Comment>> comments(String postId, {DateTime? before});
  Future<Comment> add(String postId, String body);
  Future<void> delete(String commentId);
}
