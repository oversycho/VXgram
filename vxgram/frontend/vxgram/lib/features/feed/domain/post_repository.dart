import 'new_media.dart';
import 'post.dart';

abstract class PostRepository {
  String? get currentUserId;

  /// scope: 'feed' | 'profile' | 'explore'
  Future<List<Post>> getPosts({required String scope, String? author, int limit = 15, DateTime? before});
  Future<bool> toggleLike(String postId);
  Future<void> deletePost(String postId);

  /// Uploads the files, then creates the post. [onProgress] is called after each file.
  Future<void> createPost({required String caption, required List<NewMedia> media, void Function(int done, int total)? onProgress});
}
