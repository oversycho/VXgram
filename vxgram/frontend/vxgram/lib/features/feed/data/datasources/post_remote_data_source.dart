import '../../domain/new_media.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  String? get currentUserId;
  Future<List<PostModel>> getPosts({required String scope, String? author, int limit = 15, DateTime? before});
  Future<bool> toggleLike(String postId);

  /// Deletes the row (cascade) and removes its files from storage.
  Future<void> deletePost(String postId);
  Future<void> createPost({required String caption, required List<NewMedia> media, void Function(int done, int total)? onProgress});
}
