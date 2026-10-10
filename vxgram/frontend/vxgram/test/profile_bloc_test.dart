import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/profile/bloc/profile_bloc.dart';
import 'package:vxgram/features/profile/domain/profile.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('ProfileStarted loads the profile', () async {
    final bloc = ProfileBloc(FakeProfileRepository(), 'u2')..add(const ProfileStarted());
    final s = await bloc.stream.firstWhere((s) => s.status == ProfileStatus.success);
    expect(s.profile!.username, 'maya');
    expect(s.profile!.followersCount, 5);
    await bloc.close();
  });

  test('following a public account is accepted and posts become viewable', () async {
    final bloc = ProfileBloc(FakeProfileRepository(), 'u2')..add(const ProfileStarted());
    await bloc.stream.firstWhere((s) => s.status == ProfileStatus.success);
    bloc.add(const FollowPressed());
    final s = await bloc.stream.firstWhere((s) => !s.busy && s.profile?.followStatus == FollowStatus.accepted);
    expect(s.profile!.canView, isTrue);
    await bloc.close();
  });

  test('following a private account only sends a request', () async {
    final bloc = ProfileBloc(FakeProfileRepository(private: true), 'u2')..add(const ProfileStarted());
    final first = await bloc.stream.firstWhere((s) => s.status == ProfileStatus.success);
    expect(first.profile!.canView, isFalse);
    bloc.add(const FollowPressed());
    final s = await bloc.stream.firstWhere((s) => !s.busy && s.profile?.followStatus == FollowStatus.pending);
    expect(s.profile!.canView, isFalse);
    await bloc.close();
  });

  test('unfollow cancels the relationship', () async {
    final repo = FakeProfileRepository();
    final bloc = ProfileBloc(repo, 'u2')..add(const ProfileStarted());
    await bloc.stream.firstWhere((s) => s.status == ProfileStatus.success);
    bloc.add(const FollowPressed());
    await bloc.stream.firstWhere((s) => !s.busy && s.profile?.followStatus == FollowStatus.accepted);
    bloc.add(const UnfollowPressed());
    final s = await bloc.stream.firstWhere((s) => !s.busy && s.profile?.followStatus == FollowStatus.none);
    expect(s.profile!.canView, isTrue); // public account stays viewable
    await bloc.close();
  });
}
