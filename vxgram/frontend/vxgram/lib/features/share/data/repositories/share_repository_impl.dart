import '../../../../core/failure.dart';
import '../../domain/inbox_item.dart';
import '../../domain/share_repository.dart';
import '../datasources/share_remote_data_source.dart';

class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl(this._ds);
  final ShareRemoteDataSource _ds;
  @override
  Future<int> sharePost(String postId, List<String> receiverIds, {String? message}) => guard(() => _ds.sharePost(postId, receiverIds, message));
  @override
  Future<List<InboxItem>> inbox() => guard(_ds.inbox);
  @override
  Future<void> markSeen(String id) => guard(() => _ds.markSeen(id));
}
