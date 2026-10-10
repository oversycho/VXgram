abstract class SavedRemoteDataSource {
  Future<Set<String>> savedIds();
  Future<bool> toggle(String postId);
}
