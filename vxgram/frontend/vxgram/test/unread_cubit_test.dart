import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/notifications/bloc/unread_cubit.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('refresh reads the unread count, clear resets it', () async {
    final cubit = UnreadCubit(FakeNotificationRepository(unread: 4));
    await cubit.refresh();
    expect(cubit.state, 4);
    cubit.clear();
    expect(cubit.state, 0);
    await cubit.close();
  });

  test('start polls the server; stop (logout) resets to 0', () async {
    final repo = FakeNotificationRepository(unread: 2);
    final cubit = UnreadCubit(repo, interval: const Duration(milliseconds: 5))..start();
    await cubit.stream.firstWhere((n) => n == 2);
    repo.unread = 5;
    await cubit.stream.firstWhere((n) => n == 5);
    cubit.stop();
    expect(cubit.state, 0);
    await cubit.close();
  });
}
