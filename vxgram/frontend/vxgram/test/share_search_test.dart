import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/explore/bloc/search_cubit.dart';
import 'package:vxgram/features/profile/domain/profile.dart';
import 'package:vxgram/features/share/bloc/share_cubit.dart';
import 'fakes/fake_repositories.dart';

void main() {
  const ana = UserSummary(id: '1', username: 'ana'), bob = UserSummary(id: '2', username: 'bob'), mari = UserSummary(id: '3', username: 'mari', isPrivate: true);
  const quick = Duration(milliseconds: 1);

  group('ShareCubit', () {
    test('starts with the people you follow, select + send', () async {
      final shares = FakeShareRepository();
      final cubit = ShareCubit(FakeProfileRepository(followingList: [ana, bob]), shares, 'p1', debounce: quick);
      await cubit.load();
      expect(cubit.state.users.length, 2);
      cubit.toggle('1'); cubit.toggle('2'); cubit.toggle('2'); // 2 is unselected again
      expect(cubit.state.selected, {'1'});
      await cubit.send('  look  ');
      expect(shares.sent.single, ['1']);
      expect(shares.lastMessage, 'look');
      expect(cubit.state.sent, isTrue);
      await cubit.close();
    });

    test('search replaces the list; selection is kept; empty search restores following', () async {
      final cubit = ShareCubit(FakeProfileRepository(followingList: [ana], directory: [bob, mari]), FakeShareRepository(), 'p1', debounce: quick);
      await cubit.load();
      cubit.toggle('1');
      cubit.search('mar');
      await cubit.stream.firstWhere((s) => !s.loading && s.query == 'mar');
      expect(cubit.state.users.map((u) => u.username), ['mari']);
      expect(cubit.state.selected, {'1'});
      cubit.search('');
      await cubit.stream.firstWhere((s) => !s.loading && s.query.isEmpty);
      expect(cubit.state.users.map((u) => u.username), ['ana']);
      await cubit.close();
    });

    test('send does nothing without a selection', () async {
      final shares = FakeShareRepository();
      final cubit = ShareCubit(FakeProfileRepository(followingList: [ana]), shares, 'p1', debounce: quick);
      await cubit.load();
      await cubit.send('x');
      expect(shares.sent, isEmpty);
      await cubit.close();
    });
  });

  group('SearchCubit', () {
    test('finds users by username, clears back to idle', () async {
      final cubit = SearchCubit(FakeProfileRepository(directory: [ana, bob, mari]), debounce: quick);
      cubit.onChanged('ma');
      final s = await cubit.stream.firstWhere((s) => s.status == SearchStatus.success);
      expect(s.users.map((u) => u.username), ['mari']);
      cubit.onChanged('   ');
      expect(cubit.state.status, SearchStatus.idle);
      expect(cubit.state.users, isEmpty);
      await cubit.close();
    });

    test('no match gives an empty success state', () async {
      final cubit = SearchCubit(FakeProfileRepository(directory: [ana]), debounce: quick);
      cubit.onChanged('zzz');
      final s = await cubit.stream.firstWhere((s) => s.status == SearchStatus.success);
      expect(s.users, isEmpty);
      await cubit.close();
    });
  });
}
