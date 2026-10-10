import '../../../../core/failure.dart';
import '../../domain/comment.dart';
import '../../domain/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';

class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(this._ds);
  final CommentRemoteDataSource _ds;
  @override
  String? get currentUserId => _ds.currentUserId;
  @override
  Future<List<Comment>> comments(String postId, {DateTime? before}) => guard(() => _ds.comments(postId, before));
  @override
  Future<Comment> add(String postId, String body) => guard(() => _ds.add(postId, body));
  @override
  Future<void> delete(String id) => guard(() => _ds.delete(id));
}
