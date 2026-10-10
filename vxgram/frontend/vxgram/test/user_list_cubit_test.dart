import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/profile/bloc/user_list_cubit.dart';
import 'package:vxgram/features/profile/domain/profile.dart';
import 'fakes/fake_repositories.dart';

void main() {
  const a = UserSummary(id: '1', username: 'ana'), b = UserSummary(id: '2', username: 'bob');

  test('follow requests: accepting removes the row', () async {
    final cubit = UserListCubit(FakeProfileRepository(requests: [a, b]), UserListKind.requests, 'me');
    await cubit.load();
    expect(cubit.state.users.length, 2);
    await cubit.respond(a, accept: true);
    expect(cubit.state.users.map((u) => u.id), ['2']);
    await cubit.close();
  });

  test('followers list: follow button updates the row', () async {
    final repo = FakeProfileRepository(requests: [a]);
    final cubit = UserListCubit(repo, UserListKind.requests, 'me');
    await cubit.load();
    await cubit.toggleFollow(a);
    expect(cubit.state.users.first.iFollow, FollowStatus.accepted);
    await cubit.toggleFollow(cubit.state.users.first);
    expect(cubit.state.users.first.iFollow, FollowStatus.none);
    await cubit.close();
  });
}
