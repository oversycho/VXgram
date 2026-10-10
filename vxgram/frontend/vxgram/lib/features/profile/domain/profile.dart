import 'package:equatable/equatable.dart';

enum FollowStatus {
  none, pending, accepted;
  static FollowStatus parse(String? s) => s == 'accepted' ? accepted : (s == 'pending' ? pending : none);
}

class Profile extends Equatable {
  const Profile({required this.id, required this.username, this.fullName, this.bio = '', this.avatarUrl, required this.isPrivate,
      required this.postsCount, required this.followersCount, required this.followingCount,
      required this.isMe, required this.followStatus, required this.followsMe, required this.canView});
  final String id, username, bio; final String? fullName, avatarUrl;
  final bool isPrivate, isMe, followsMe, canView;
  final int postsCount, followersCount, followingCount; final FollowStatus followStatus;
  @override
  List<Object?> get props => [id, username, fullName, bio, avatarUrl, isPrivate, postsCount, followersCount, followingCount, followStatus, followsMe, canView];
}

class UserSummary extends Equatable {
  const UserSummary({required this.id, required this.username, this.fullName, this.avatarUrl, this.iFollow = FollowStatus.none});
  final String id, username; final String? fullName, avatarUrl; final FollowStatus iFollow;
  UserSummary copyWith({FollowStatus? iFollow}) =>
      UserSummary(id: id, username: username, fullName: fullName, avatarUrl: avatarUrl, iFollow: iFollow ?? this.iFollow);
  @override
  List<Object?> get props => [id, iFollow];
}
