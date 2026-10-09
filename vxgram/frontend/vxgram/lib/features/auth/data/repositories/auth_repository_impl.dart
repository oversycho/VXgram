import '../../../../core/failure.dart';
import '../../domain/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Depends on the DataSource *interface*; maps SDK exceptions to AppFailure.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._ds);
  final AuthRemoteDataSource _ds;

  @override
  bool get isSignedIn => _ds.isSignedIn;
  @override
  Stream<bool> get signedInStream => _ds.signedInStream;

  @override
  Future<void> signIn(String email, String password) => guard(() => _ds.signIn(email.trim(), password));
  @override
  Future<bool> signUp({required String email, required String password, required String username, required String fullName}) =>
      guard(() => _ds.signUp(email: email.trim(), password: password, username: username.trim(), fullName: fullName.trim()));
  @override
  Future<void> signOut() => guard(_ds.signOut);
  @override
  Future<void> updatePassword(String password) => guard(() => _ds.updatePassword(password));
  @override
  Future<void> resetPassword(String email) => guard(() => _ds.resetPassword(email.trim()));
  @override
  Future<bool> usernameAvailable(String u) => guard(() => _ds.usernameAvailable(u.trim()));
}
