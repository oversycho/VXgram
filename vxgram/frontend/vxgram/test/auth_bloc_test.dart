import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/features/auth/bloc/auth_bloc.dart';
import 'fakes/fake_repositories.dart';

void main() {
  test('login success: busy then idle, no error', () async {
    final bloc = AuthBloc(FakeAuthRepository());
    final done = expectLater(bloc.stream, emitsInOrder([
      predicate<AuthState>((s) => s.busy && s.error == null),
      predicate<AuthState>((s) => !s.busy && s.error == null),
    ]));
    bloc.add(const LoginSubmitted('a@b.co', '123456'));
    await done;
    await bloc.close();
  });

  test('login failure: error message from repository is exposed', () async {
    final bloc = AuthBloc(FakeAuthRepository(failWith: 'Invalid login credentials'));
    final done = expectLater(bloc.stream, emitsInOrder([
      predicate<AuthState>((s) => s.busy),
      predicate<AuthState>((s) => !s.busy && s.error == 'Invalid login credentials'),
    ]));
    bloc.add(const LoginSubmitted('a@b.co', 'wrong'));
    await done;
    await bloc.close();
  });
}
