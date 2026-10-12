import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/notifications/bloc/notifications_cubit.dart';
import 'package:vxgram/features/notifications/domain/app_notification.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('load lists the items, marks everything read and clears the badge; items keep their unread flag', () async {
    final repo = FakeNotificationRepository(items: [fakeNotification('1'), fakeNotification('2', read: true)], unread: 1);
    var cleared = 0;
    final cubit = NotificationsCubit(repo, FakeProfileRepository(), onMarkedRead: () => cleared++);
    await cubit.load();
    expect(cubit.state.status, NotificationsStatus.success);
    expect(cubit.state.items.length, 2);
    expect(cubit.state.items.first.read, isFalse); // still highlighted in this session
    expect(repo.markedRead, isTrue);
    expect(cleared, 1);
    await cubit.close();
  });

  test('confirming a follow request tells the server and removes the row', () async {
    final profiles = FakeProfileRepository();
    final req = fakeNotification('7', type: NotificationType.followRequest, actor: 'u9');
    final cubit = NotificationsCubit(FakeNotificationRepository(items: [req, fakeNotification('8')]), profiles);
    await cubit.load();
    await cubit.respond(req, accept: true);
    expect(profiles.responded, ['u9:true']);
    expect(cubit.state.items.map((n) => n.id), ['8']);
    await cubit.close();
  });

  test('deleting a follow request sends accept: false', () async {
    final profiles = FakeProfileRepository();
    final req = fakeNotification('7', type: NotificationType.followRequest, actor: 'u9');
    final cubit = NotificationsCubit(FakeNotificationRepository(items: [req]), profiles);
    await cubit.load();
    await cubit.respond(req, accept: false);
    expect(profiles.responded, ['u9:false']);
    expect(cubit.state.items, isEmpty);
    await cubit.close();
  });
}
