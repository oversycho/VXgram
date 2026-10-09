import 'package:vxgram/core/failure.dart';
import 'package:vxgram/features/auth/domain/auth_repository.dart';
import 'package:vxgram/features/feed/domain/post.dart';
import 'package:vxgram/features/feed/domain/post_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failWith});
  final String? failWith;
  @override bool get isSignedIn => false;
  @override Stream<bool> get signedInStream => const Stream.empty();
  Future<void> _maybeFail() async { if (failWith != null) throw AppFailure(failWith!); }
  @override Future<void> signIn(String email, String password) => _maybeFail();
  @override Future<bool> signUp({required String email, required String password, required String username, required String fullName}) async { await _maybeFail(); return true; }
  @override Future<void> signOut() => _maybeFail();
  @override Future<void> updatePassword(String password) => _maybeFail();
  @override Future<void> resetPassword(String email) => _maybeFail();
  @override Future<bool> usernameAvailable(String username) async => true;
}

Post fakePost(String id, {bool liked = false, int likes = 0}) => Post(
    id: id, userId: 'u1', username: 'maya', caption: 'hi', createdAt: DateTime(2026, 1, 1),
    likesCount: likes, commentsCount: 0, likedByMe: liked, media: const []);

class FakePostRepository implements PostRepository {
  FakePostRepository(this.posts, {this.failLike = false});
  final List<Post> posts; final bool failLike;
  @override String? get currentUserId => 'u1';
  @override Future<List<Post>> getPosts({required String scope, String? author, int limit = 15, DateTime? before}) async => posts;
  @override Future<bool> toggleLike(String postId) async { if (failLike) throw AppFailure('offline'); return true; }
  @override Future<void> deletePost(String postId) async {}
}
