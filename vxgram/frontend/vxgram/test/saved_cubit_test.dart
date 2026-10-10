import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/saved/bloc/saved_cubit.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('load fills the saved ids; clear empties them (logout)', () async {
    final cubit = SavedCubit(FakeSavedRepository(initial: {'a', 'b'}));
    await cubit.load();
    expect(cubit.state.ids, {'a', 'b'});
    cubit.clear();
    expect(cubit.state.ids, isEmpty);
    await cubit.close();
  });

  test('toggle saves and unsaves', () async {
    final repo = FakeSavedRepository();
    final cubit = SavedCubit(repo);
    expect(await cubit.toggle('p1'), isTrue);
    expect(cubit.state.ids, {'p1'});
    expect(repo.ids, {'p1'});
    expect(await cubit.toggle('p1'), isTrue);
    expect(cubit.state.ids, isEmpty);
    await cubit.close();
  });

  test('toggle is optimistic and reverts with an error when the server fails', () async {
    final cubit = SavedCubit(FakeSavedRepository(fail: true));
    final states = <Set<String>>[];
    final sub = cubit.stream.listen((s) => states.add(s.ids));
    final ok = await cubit.toggle('p1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(ok, isFalse);
    expect(states.first, {'p1'});          // shown immediately
    expect(cubit.state.ids, isEmpty);      // reverted
    expect(cubit.state.error, 'offline');
    await cubit.close();
  });
}
