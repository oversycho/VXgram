/// Raw backend access (no error mapping). Swap the implementation to change backend.
abstract class AuthRemoteDataSource {
  bool get isSignedIn;
  Stream<bool> get signedInStream;
  Future<void> signIn(String email, String password);
  Future<bool> signUp({required String email, required String password, required String username, required String fullName});
  Future<void> signOut();
  Future<void> updatePassword(String password);
  Future<void> resetPassword(String email);
  Future<bool> usernameAvailable(String username);
}
