import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  String? get currentUserId;
  Future<List<CommentModel>> comments(String postId, DateTime? before);
  Future<CommentModel> add(String postId, String body);
  Future<void> delete(String commentId);
}
