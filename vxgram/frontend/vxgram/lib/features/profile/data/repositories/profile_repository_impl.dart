import 'dart:typed_data';
import '../../../../core/failure.dart';
import '../../domain/profile.dart';
import '../../domain/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._ds);
  final ProfileRemoteDataSource _ds;

  @override
  String? get currentUserId => _ds.currentUserId;
  @override
  Future<Profile> getProfile(String id) => guard(() => _ds.getProfile(id));
  @override
  Future<FollowStatus> follow(String id) => guard(() => _ds.follow(id));
  @override
  Future<void> unfollow(String id) => guard(() => _ds.unfollow(id));
  @override
  Future<List<UserSummary>> followers(String id, {int offset = 0}) => guard(() => _ds.followers(id, offset));
  @override
  Future<List<UserSummary>> following(String id, {int offset = 0}) => guard(() => _ds.following(id, offset));
  @override
  Future<List<UserSummary>> followRequests() => guard(_ds.followRequests);
  @override
  Future<List<UserSummary>> searchUsers(String q) => guard(() => _ds.searchUsers(q));
  @override
  Future<void> respondToRequest(String followerId, {required bool accept}) => guard(() => _ds.respondToRequest(followerId, accept));
  @override
  Future<void> removeFollower(String id) => guard(() => _ds.removeFollower(id));
  @override
  Future<void> updateProfile({String? fullName, String? bio, String? username}) =>
      guard(() => _ds.updateProfile(fullName: fullName, bio: bio, username: username));
  @override
  Future<void> setPrivate(bool v) => guard(() => _ds.setPrivate(v));
  @override
  Future<void> updateAvatar(Uint8List bytes, String ext) => guard(() => _ds.updateAvatar(bytes, ext));
}
