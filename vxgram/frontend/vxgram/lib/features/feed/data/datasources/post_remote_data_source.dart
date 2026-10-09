import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  String? get currentUserId;
  Future<List<PostModel>> getPosts({required String scope, String? author, int limit = 15, DateTime? before});
  Future<bool> toggleLike(String postId);

  /// Deletes the row (cascade) and removes its files from storage.
  Future<void> deletePost(String postId);
}
