import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/comments/bloc/comments_cubit.dart';
import 'package:vxgram/features/comments/domain/comment.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('load shows existing comments', () async {
    final repo = FakeCommentRepository([Comment(id: 'c0', userId: 'u2', username: 'ana', body: 'nice', createdAt: DateTime(2026))]);
    final cubit = CommentsCubit(repo, 'p1');
    await cubit.load();
    expect(cubit.state.status, CommentsStatus.success);
    expect(cubit.state.comments.single.body, 'nice');
    await cubit.close();
  });

  test('send adds the comment on top and reports +1; blank text is ignored', () async {
    final deltas = <int>[];
    final cubit = CommentsCubit(FakeCommentRepository(), 'p1', onCountChanged: deltas.add);
    await cubit.load();
    expect(await cubit.send('   '), isFalse);
    expect(await cubit.send(' hello '), isTrue);
    expect(cubit.state.comments.first.body, 'hello');
    expect(deltas, [1]);
    await cubit.close();
  });

  test('delete removes the comment and reports -1', () async {
    final deltas = <int>[];
    final cubit = CommentsCubit(FakeCommentRepository(), 'p1', onCountChanged: deltas.add);
    await cubit.load();
    await cubit.send('bye');
    await cubit.delete(cubit.state.comments.first);
    expect(cubit.state.comments, isEmpty);
    expect(deltas, [1, -1]);
    await cubit.close();
  });
}
