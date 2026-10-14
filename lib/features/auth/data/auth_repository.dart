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
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    // The Auth trigger creates profiles. A successful login must never depend
    // on a second network write or an INSERT policy on the profiles table.
  }

  Future<AuthResponse> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String country,
    required String city,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
        'country': country.trim(),
        'city': city.trim(),
      },
    );
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
    required String country,
    required String city,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': name.trim(),
          'phone': phone.trim(),
          'country': country.trim(),
          'city': city.trim(),
        },
      ),
    );
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('profiles')
        .update({'full_name': name.trim(), 'phone': phone.trim()})
        .eq('id', user.id);
  }

  Future<void> signOut() => _client.auth.signOut();
}
