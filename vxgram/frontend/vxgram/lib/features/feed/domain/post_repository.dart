import 'post.dart';

abstract class PostRepository {
  String? get currentUserId;

  /// scope: 'feed' | 'profile' | 'explore'
  Future<List<Post>> getPosts({required String scope, String? author, int limit = 15, DateTime? before});
  Future<bool> toggleLike(String postId);
  Future<void> deletePost(String postId);
}
