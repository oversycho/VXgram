import 'package:vxgram/core/failure.dart';
import 'package:vxgram/features/auth/domain/auth_repository.dart';
import 'package:vxgram/features/feed/domain/post.dart';
import 'package:vxgram/features/feed/domain/post_repository.dart';
import 'package:vxgram/features/profile/domain/profile.dart';
import 'package:vxgram/features/profile/domain/profile_repository.dart';
import 'dart:typed_data';

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

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.private = false, List<UserSummary>? requests}) : requests = requests ?? [];
  final bool private; final List<UserSummary> requests;
  FollowStatus status = FollowStatus.none;

  @override String? get currentUserId => 'me';
  @override Future<Profile> getProfile(String userId) async => Profile(
      id: userId, username: 'maya', isPrivate: private, postsCount: 2, followersCount: 5, followingCount: 7, isMe: false,
      followStatus: status, followsMe: false, canView: !private || status == FollowStatus.accepted);
  @override Future<FollowStatus> follow(String userId) async => status = private ? FollowStatus.pending : FollowStatus.accepted;
  @override Future<void> unfollow(String userId) async { status = FollowStatus.none; }
  @override Future<List<UserSummary>> followers(String userId, {int offset = 0}) async => [];
  @override Future<List<UserSummary>> following(String userId, {int offset = 0}) async => [];
  @override Future<List<UserSummary>> followRequests() async => List.of(requests);
  @override Future<void> respondToRequest(String followerId, {required bool accept}) async {}
  @override Future<void> removeFollower(String followerId) async {}
  @override Future<void> updateProfile({String? fullName, String? bio, String? username}) async {}
  @override Future<void> setPrivate(bool value) async {}
  @override Future<void> updateAvatar(Uint8List bytes, String ext) async {}
}
