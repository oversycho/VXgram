import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/failure.dart';
import '../domain/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

abstract class AuthEvent { const AuthEvent(); }
class AuthStarted extends AuthEvent { const AuthStarted(); }
class LoginSubmitted extends AuthEvent { const LoginSubmitted(this.email, this.password); final String email, password; }
class SignUpSubmitted extends AuthEvent {
  const SignUpSubmitted({required this.email, required this.password, required this.username, required this.fullName});
  final String email, password, username, fullName;
}
class ResetRequested extends AuthEvent { const ResetRequested(this.email); final String email; }
class PasswordChangeSubmitted extends AuthEvent { const PasswordChangeSubmitted(this.password); final String password; }
class LogoutPressed extends AuthEvent { const LogoutPressed(); }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.busy = false, this.error, this.notice});
  final AuthStatus status; final bool busy;
  final String? error;   // raw backend message
  final String? notice;  // l10n key (one-shot)
  AuthState copyWith({AuthStatus? status, bool? busy, String? error, String? notice, bool clear = false}) => AuthState(
      status: status ?? this.status, busy: busy ?? this.busy, error: clear ? null : (error ?? this.error), notice: clear ? null : (notice ?? this.notice));
  @override
  List<Object?> get props => [status, busy, error, notice];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>((e, emit) async {
      emit(state.copyWith(status: _repo.isSignedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated));
      await emit.forEach<bool>(_repo.signedInStream,
          onData: (s) => state.copyWith(status: s ? AuthStatus.authenticated : AuthStatus.unauthenticated, busy: false));
    });
    on<LoginSubmitted>((e, emit) => _run(emit, () => _repo.signIn(e.email, e.password)));
    on<SignUpSubmitted>((e, emit) => _run(emit, () async {
          final signedIn = await _repo.signUp(email: e.email, password: e.password, username: e.username, fullName: e.fullName);
          if (!signedIn) emit(state.copyWith(notice: 'confirm_email'));
        }));
    on<ResetRequested>((e, emit) => _run(emit, () async { await _repo.resetPassword(e.email); emit(state.copyWith(notice: 'reset_sent')); }));
    on<PasswordChangeSubmitted>((e, emit) => _run(emit, () async { await _repo.updatePassword(e.password); emit(state.copyWith(notice: 'password_updated')); }));
    on<LogoutPressed>((e, emit) => _run(emit, _repo.signOut));
  }
  final AuthRepository _repo;

  Future<void> _run(Emitter<AuthState> emit, Future<void> Function() action) async {
    emit(state.copyWith(busy: true, clear: true));
    try {
      await action();
      emit(state.copyWith(busy: false));
    } on AppFailure catch (f) {
      emit(state.copyWith(busy: false, error: f.message));
    }
  }
}
