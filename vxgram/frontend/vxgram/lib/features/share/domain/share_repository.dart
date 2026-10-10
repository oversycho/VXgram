import 'inbox_item.dart';

abstract class ShareRepository {
  /// Sends a post to other users. Returns how many were sent.
  Future<int> sharePost(String postId, List<String> receiverIds, {String? message});
  Future<List<InboxItem>> inbox();
  Future<void> markSeen(String shareId);
}
