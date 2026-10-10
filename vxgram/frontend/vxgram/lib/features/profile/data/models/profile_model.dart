import '../../domain/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({required super.id, required super.username, super.fullName, super.bio, super.avatarUrl, required super.isPrivate,
      required super.postsCount, required super.followersCount, required super.followingCount,
      required super.isMe, required super.followStatus, required super.followsMe, required super.canView});

  /// One row of the `get_profile` RPC.
  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id: j['id'], username: j['username'].toString(), fullName: j['full_name'], bio: j['bio'] ?? '', avatarUrl: j['avatar_url'],
        isPrivate: j['is_private'] ?? false, postsCount: j['posts_count'] ?? 0, followersCount: j['followers_count'] ?? 0,
        followingCount: j['following_count'] ?? 0, isMe: j['is_me'] ?? false, followStatus: FollowStatus.parse(j['follow_status'] as String?),
        followsMe: j['follows_me'] ?? false, canView: j['can_view'] ?? false,
      );
}

class UserSummaryModel extends UserSummary {
  const UserSummaryModel({required super.id, required super.username, super.fullName, super.avatarUrl, super.iFollow, super.isPrivate});
  factory UserSummaryModel.fromJson(Map<String, dynamic> j) => UserSummaryModel(
      id: j['id'], username: j['username'].toString(), fullName: j['full_name'], avatarUrl: j['avatar_url'],
      iFollow: FollowStatus.parse(j['i_follow'] as String?), isPrivate: j['is_private'] ?? false);
}
