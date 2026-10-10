import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/create/bloc/create_post_bloc.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('submit uploads, reports progress and ends as posted', () async {
    final repo = FakePostRepository([]);
    final bloc = CreatePostBloc(repo);
    bloc.add(MediaAdded([fakeMedia(), fakeMedia('mp4')]));
    bloc.add(const CaptionChanged('my caption'));
    await bloc.stream.firstWhere((s) => s.caption == 'my caption');
    final progress = <int>[];
    final sub = bloc.stream.listen((s) { if (s.uploading) progress.add(s.done); });
    bloc.add(const PostSubmitted());
    final end = await bloc.stream.firstWhere((s) => s.posted);
    await sub.cancel();
    expect(repo.created, ['my caption']);
    expect(progress, containsAll([0, 2]));
    expect(end.uploading, isFalse);
    await bloc.close();
  });

  test('submit without media does nothing', () async {
    final repo = FakePostRepository([]);
    final bloc = CreatePostBloc(repo)..add(const PostSubmitted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.created, isEmpty);
    expect(bloc.state.uploading, isFalse);
    await bloc.close();
  });

  test('upload failure keeps the media and exposes the error', () async {
    final bloc = CreatePostBloc(FakePostRepository([], failCreate: true))..add(MediaAdded([fakeMedia()]));
    await bloc.stream.firstWhere((s) => s.media.length == 1);
    bloc.add(const PostSubmitted());
    final s = await bloc.stream.firstWhere((s) => s.error != null);
    expect(s.error, 'upload failed');
    expect(s.media.length, 1);
    expect(s.uploading, isFalse);
    await bloc.close();
  });

  test('at most 10 items and removal works', () async {
    final bloc = CreatePostBloc(FakePostRepository([]));
    bloc.add(MediaAdded(List.generate(12, (_) => fakeMedia())));
    final full = await bloc.stream.firstWhere((s) => s.media.isNotEmpty);
    expect(full.media.length, 10);
    bloc.add(const MediaRemoved(0));
    final less = await bloc.stream.firstWhere((s) => s.media.length == 9);
    expect(less.media.length, 9);
    await bloc.close();
  });
}
