import 'dart:typed_data';
import '../../domain/profile.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  String? get currentUserId;
  Future<ProfileModel> getProfile(String userId);
  Future<FollowStatus> follow(String userId);
  Future<void> unfollow(String userId);
  Future<List<UserSummaryModel>> followers(String userId, int offset);
  Future<List<UserSummaryModel>> following(String userId, int offset);
  Future<List<UserSummaryModel>> followRequests();
  Future<List<UserSummaryModel>> searchUsers(String query);
  Future<void> respondToRequest(String followerId, bool accept);
  Future<void> removeFollower(String followerId);
  Future<void> updateProfile({String? fullName, String? bio, String? username});
  Future<void> setPrivate(bool value);
  Future<void> updateAvatar(Uint8List bytes, String ext);
}
