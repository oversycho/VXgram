import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/feed/bloc/feed_bloc.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('FeedStarted: loading then success with posts', () async {
    final bloc = FeedBloc(FakePostRepository([fakePost('1'), fakePost('2')]));
    final done = expectLater(bloc.stream, emitsInOrder([
      predicate<FeedState>((s) => s.status == FeedStatus.loading),
      predicate<FeedState>((s) => s.status == FeedStatus.success && s.posts.length == 2),
    ]));
    bloc.add(const FeedStarted());
    await done;
    await bloc.close();
  });

  test('like is optimistic', () async {
    final bloc = FeedBloc(FakePostRepository([fakePost('1', likes: 3)]));
    bloc.add(const FeedStarted());
    await bloc.stream.firstWhere((s) => s.status == FeedStatus.success);
    final liked = expectLater(bloc.stream, emits(predicate<FeedState>((s) => s.posts.first.likedByMe && s.posts.first.likesCount == 4)));
    bloc.add(const FeedLikeToggled('1'));
    await liked;
    await bloc.close();
  });

  test('like is reverted when the repository fails', () async {
    final bloc = FeedBloc(FakePostRepository([fakePost('1', likes: 3)], failLike: true));
    bloc.add(const FeedStarted());
    await bloc.stream.firstWhere((s) => s.status == FeedStatus.success);
    final reverted = expectLater(bloc.stream, emitsInOrder([
      predicate<FeedState>((s) => s.posts.first.likedByMe),
      predicate<FeedState>((s) => !s.posts.first.likedByMe && s.posts.first.likesCount == 3 && s.error == 'offline'),
    ]));
    bloc.add(const FeedLikeToggled('1'));
    await reverted;
    await bloc.close();
  });
}
