import 'dart:typed_data';
import 'profile.dart';

abstract class ProfileRepository {
  String? get currentUserId;
  Future<Profile> getProfile(String userId);

  /// Returns pending (private account) or accepted.
  Future<FollowStatus> follow(String userId);
  Future<void> unfollow(String userId); // also cancels a pending request
  Future<List<UserSummary>> followers(String userId, {int offset = 0});
  Future<List<UserSummary>> following(String userId, {int offset = 0});
  Future<List<UserSummary>> followRequests();
  Future<void> respondToRequest(String followerId, {required bool accept});
  Future<void> removeFollower(String followerId);

  Future<void> updateProfile({String? fullName, String? bio, String? username});
  Future<void> setPrivate(bool value);
  Future<void> updateAvatar(Uint8List bytes, String ext);
}
