import '../../../../core/failure.dart';
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
}
