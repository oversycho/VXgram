import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/notifications/data/models/notification_model.dart';
import 'package:vxgram/features/notifications/domain/app_notification.dart';

void main() {
  Map<String, dynamic> row(String type, {bool read = false}) => {
        'id': 'n1', 'type': type, 'actor_id': 'u2', 'actor_username': 'ana', 'actor_avatar': null, 'post_id': 'p1',
        'thumb_url': 'https://x/t.jpg', 'body': 'nice', 'is_read': read, 'created_at': '2026-01-01T00:00:00Z',
      };

  test('every backend type maps to an enum value; unknown types do not crash', () {
    expect(NotificationModel.fromJson(row('like')).type, NotificationType.like);
    expect(NotificationModel.fromJson(row('comment')).type, NotificationType.comment);
    expect(NotificationModel.fromJson(row('follow')).type, NotificationType.follow);
    expect(NotificationModel.fromJson(row('follow_request')).type, NotificationType.followRequest);
    expect(NotificationModel.fromJson(row('follow_accepted')).type, NotificationType.followAccepted);
    expect(NotificationModel.fromJson(row('something_new')).type, NotificationType.other);
  });

  test('fields are mapped', () {
    final n = NotificationModel.fromJson(row('comment', read: true));
    expect(n.actorUsername, 'ana');
    expect(n.body, 'nice');
    expect(n.thumbUrl, 'https://x/t.jpg');
    expect(n.read, isTrue);
  });
}
