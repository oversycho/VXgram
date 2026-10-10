import '../../../../core/failure.dart';
import '../../domain/new_media.dart';
import '../../domain/post.dart';
import '../../domain/post_repository.dart';
import '../datasources/post_remote_data_source.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._ds);
  final PostRemoteDataSource _ds;

  @override
  String? get currentUserId => _ds.currentUserId;

  @override
  Future<List<Post>> getPosts({required String scope, String? author, int limit = 15, DateTime? before}) =>
      guard(() => _ds.getPosts(scope: scope, author: author, limit: limit, before: before));
  @override
  Future<bool> toggleLike(String id) => guard(() => _ds.toggleLike(id));
  @override
  Future<void> deletePost(String id) => guard(() => _ds.deletePost(id));

  @override
  Future<void> createPost({required String caption, required List<NewMedia> media, void Function(int done, int total)? onProgress}) => guard(() async {
        if (media.isEmpty) throw AppFailure('Select at least one photo or video');
        if (media.length > NewMedia.maxItems) throw AppFailure('Up to ${NewMedia.maxItems} items per post');
        for (final m in media) {
          if (!m.isSupported) throw AppFailure('Unsupported file type: .${m.ext}');
          if (m.bytes.length > NewMedia.maxBytes) throw AppFailure('File too large (max 100 MB)');
        }
        await _ds.createPost(caption: caption.trim(), media: media, onProgress: onProgress);
      });
}
