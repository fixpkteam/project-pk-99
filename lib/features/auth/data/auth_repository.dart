import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<User?> get userChanges async* {
    yield _client.auth.currentUser;
    yield* _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user != null) await _syncProfile(user);
  }

  Future<AuthResponse> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim(), 'phone': phone.trim()},
    );
    final user = response.user;
    if (response.session != null && user != null) {
      await _syncProfile(user);
    }
    return response;
  }

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb
            ? Uri.base.replace(path: '/', query: '', fragment: '').toString()
            : 'com.fixpk.fixpk://login-callback/',
      );

  Future<void> updatePassword(String password) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('Open a valid password reset link first.');
    }
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': name.trim(), 'phone': phone.trim()}),
    );
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': name.trim(),
      'phone': phone.trim(),
    });
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> _syncProfile(User user) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': metadata['full_name'] ?? metadata['name'] ?? '',
      'phone': metadata['phone'] ?? '',
    });
  }
}
