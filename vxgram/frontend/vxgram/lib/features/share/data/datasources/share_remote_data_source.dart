import '../models/inbox_item_model.dart';

abstract class ShareRemoteDataSource {
  Future<int> sharePost(String postId, List<String> receiverIds, String? message);
  Future<List<InboxItemModel>> inbox();
  Future<void> markSeen(String shareId);
}
