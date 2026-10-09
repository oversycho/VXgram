/// Contract used by blocs/UI. Implementations live in data/repositories.
abstract class AuthRepository {
  bool get isSignedIn;
  Stream<bool> get signedInStream;

  Future<void> signIn(String email, String password);

  /// Returns true when a session exists (false => email confirmation required).
  Future<bool> signUp({required String email, required String password, required String username, required String fullName});
  Future<void> signOut();
  Future<void> updatePassword(String password);
  Future<void> resetPassword(String email);
  Future<bool> usernameAvailable(String username);
}
