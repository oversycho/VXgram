abstract class SavedRepository {
  /// Ids of every post the signed-in user saved (drives the bookmark icon on every card).
  Future<Set<String>> savedIds();
  /// true = saved now, false = removed.
  Future<bool> toggle(String postId);
}
