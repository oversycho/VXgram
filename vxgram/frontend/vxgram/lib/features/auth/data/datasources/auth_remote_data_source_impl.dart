import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._c);
  final SupabaseClient _c;

  @override
  bool get isSignedIn => _c.auth.currentSession != null;
  @override
  Stream<bool> get signedInStream => _c.auth.onAuthStateChange.map((e) => e.session != null);

  @override
  Future<void> signIn(String email, String password) async {
    await _c.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({required String email, required String password, required String username, required String fullName}) async {
    final r = await _c.auth.signUp(email: email, password: password, data: {'username': username.toLowerCase(), 'full_name': fullName});
    return r.session != null;
  }

  @override
  Future<void> signOut() => _c.auth.signOut();
  @override
  Future<void> updatePassword(String password) async { await _c.auth.updateUser(UserAttributes(password: password)); }
  @override
  Future<void> resetPassword(String email) => _c.auth.resetPasswordForEmail(email);

  @override
  Future<bool> usernameAvailable(String username) async {
    final r = await _c.from('profiles').select('id').eq('username', username.toLowerCase()).maybeSingle();
    return r == null;
  }
}
