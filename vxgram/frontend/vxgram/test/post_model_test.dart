import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/feed/data/models/post_model.dart';

Map<String, dynamic> row(List<Map<String, dynamic>> media) => {
      'id': 'p1', 'user_id': 'u1', 'username': 'maya', 'avatar_url': null, 'caption': 'hi', 'created_at': '2026-01-01T00:00:00Z',
      'likes_count': 1, 'comments_count': 0, 'liked_by_me': false, 'media': media,
    };

void main() {
  test('media thumbnail url is mapped when present', () {
    final p = PostModel.fromJson(row([
      {'id': 'm1', 'url': 'https://x/v.mp4', 'thumb_url': 'https://x/v_thumb.jpg', 'type': 'video', 'position': 0},
    ]));
    expect(p.media.single.isVideo, isTrue);
    expect(p.media.single.thumbUrl, 'https://x/v_thumb.jpg');
  });

  test('older posts without a thumbnail still parse (thumbUrl is null)', () {
    final p = PostModel.fromJson(row([
      {'id': 'm1', 'url': 'https://x/a.jpg', 'type': 'image', 'position': 0},
    ]));
    expect(p.media.single.thumbUrl, isNull);
    expect(p.media.single.url, 'https://x/a.jpg');
  });
}
